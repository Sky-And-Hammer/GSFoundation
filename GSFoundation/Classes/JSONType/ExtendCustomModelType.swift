//
//  ExtendCustomModelType.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation
import GSStability

public protocol _ExtendCustomModelType: _Transformable {
    
    init()
    mutating func mapping(mapper: Mapper)
    mutating func didFinishMapping()
}

public extension _ExtendCustomModelType {
    mutating func mapping(mapper: Mapper) {}
    mutating func didFinishMapping() {}
}

fileprivate func convertKeyIfNeed(dict: [String: Any]) -> [String: Any] {
    guard GSJSONConfiguration.deserializeOptions != .defaultOptions else { return dict }
    var result = [String: Any].init()
    dict.forEach {
        var key = $0.key
        if GSJSONConfiguration.deserializeOptions.contains(.caseInsensitive) { key = key.lowercased() }
        if GSJSONConfiguration.deserializeOptions.contains(.caseUnderScore) { key = key.replacingOccurrences(of: "_", with: "") }
        result[key] = $0.value
    }
    
    return result
}

fileprivate func getRawValueFrom(dict: [String: Any], property: PropertyInfo, mapper: Mapper) -> Any? {
    if let mappingHandler = mapper.getMappingHandler(key: property.address.hashValue),
        let mappingPaths = mappingHandler.mappingPaths,
        mappingPaths.count > 0 {
        for path in mappingPaths { if let _value = dict.findValue(byPath: path) { return _value} }
        return nil
    }
    
    guard GSJSONConfiguration.deserializeOptions != .defaultOptions else { return dict[property.key] }
    var key = property.key
    if GSJSONConfiguration.deserializeOptions.contains(.caseInsensitive) { key = key.lowercased() }
    if GSJSONConfiguration.deserializeOptions.contains(.caseUnderScore) { key = key.replacingOccurrences(of: "_", with: "") }
    
    return dict[key]
}

fileprivate func convertValue(rawValue: Any, property: PropertyInfo, mapper: Mapper) -> Any? {
    if let mapperHandler = mapper.getMappingHandler(key: property.address.hashValue),
        let transformer = mapperHandler.assingmentClosure {
        return transformer(rawValue)
    } else if let transformableType = property.type as? _Transformable.Type { return transformableType.transform(from: rawValue) }
    else { return extensions(of: property.type).takeValue(from: rawValue) }
}

fileprivate func assignProperty(convertedValue: Any, instance: _ExtendCustomModelType, property: PropertyInfo) {
    if property.bridged { (instance as? NSObject)?.setValue(convertedValue, forKey: property.key) }
    else { extensions(of: property.type).write(convertedValue, to: property.address) }
}

fileprivate func readAllChildrenFrom(mirror: Mirror) -> [(String, Any)] {
    var children = [(label: String?, value: Any)].init()
    let mirrorChildrenCollection = AnyRandomAccessCollection.init(mirror.children)!
    children += mirrorChildrenCollection
    var currentMirror = mirror
    while let superclassChildren = currentMirror.superclassMirror?.children {
        let randomCollection = AnyRandomAccessCollection.init(superclassChildren)!
        children += randomCollection
        currentMirror = currentMirror.superclassMirror!
    }
    
    var result = [(String, Any)].init()
    children.forEach { if let _label = $0.label { result.append((_label, $0.value)) } }
    return result
}

fileprivate func merge(children: [(String, Any)], propertyInfos: [PropertyInfo]) -> [String:(Any, PropertyInfo?)] {
    var infoDict = [String: PropertyInfo].init()
    propertyInfos.forEach { infoDict[$0.key] = $0 }
    var result = [String: (Any, PropertyInfo?)].init()
    children.forEach { result[$0.0] = ($0.1, infoDict[$0.0]) }
    return result
}

extension NSObject { static func instance() -> NSObject { return self.init() } }
extension _ExtendCustomModelType {
    
    static func _transform(from object: Any) -> Self? {
        guard let dic = object as? [String: Any] else { return nil }
        return _transform(dict: dic) as? Self
    }
    
    static func _transform(dict: [String: Any]) -> _ExtendCustomModelType? {
        var instance: Self
        if let _nsType = Self.self as? NSObject.Type { instance = _nsType.instance() as! Self }
        else { instance = Self.init() }
        _transform(dict: dict, to: &instance)
        instance.didFinishMapping()
        return instance
    }
    
    static func _transform(dict: [String: Any], to instance: inout Self) {
        guard let properties = getProperties(forType: Self.self) else {
            Logger.error("Failed when try to get properties from type: \(type(of: Self.self))")
            return
        }
        
        // do user-specified mapping first
        let mapper = Mapper.init()
        instance.mapping(mapper: mapper)
        
        // get head address
        let rawPointer = instance.headPointer()
        Logger.verbose("instance start at: \(rawPointer.hashValue)")
        
        let _dict = convertKeyIfNeed(dict: dict)
        
        let instanceIsNSObject = instance.isNSObjectType()
        let bridgedPropertyList = instance.getBridgePropertyLost()
        properties.forEach {
            let isbridgedProperty = instanceIsNSObject && bridgedPropertyList.contains($0.key)
            let propAddress = rawPointer.advanced(by: $0.offset)
            Logger.verbose("\($0.key) address at: \(propAddress.hashValue)")
            if mapper.propertyExcluded(key: propAddress.hashValue) { Logger.verbose("execlud property: \($0.key)"); return }
            
            let propertyDetail = PropertyInfo.init(key: $0.key, type: $0.type, address: propAddress, bridged: isbridgedProperty)
            Logger.verbose("field: \($0.key) offset: \($0.offset) isBirdgeProperty: \(isbridgedProperty)")
            if let rawValue = getRawValueFrom(dict: _dict, property: propertyDetail, mapper: mapper),
                let convertedValue = convertValue(rawValue: rawValue, property: propertyDetail, mapper: mapper) {
                assignProperty(convertedValue: convertedValue, instance: instance, property: propertyDetail)
                return
            }
            
            Logger.verbose("property: \($0.key) hasn't been written in")
        }
    }
}

extension _ExtendCustomModelType {
    
    func _plainValue() -> Any? { return Self._serializeAny(object: self) }
    static func _serializeAny(object: _Transformable) -> Any? {
        let mirror = Mirror.init(reflecting: object)
        guard let displayStyle = mirror.displayStyle else { return object.plainValue() }
        
        switch displayStyle {
        case .class, .struct:
            let mapper = Mapper.init()
            guard object is _ExtendCustomModelType else {
                Logger.verbose("this model of type: \(type(of: object)) is not mappable but is class/struct type")
                return object
            }
            
            let children = readAllChildrenFrom(mirror: mirror)
            guard let properties = getProperties(forType: type(of: object)) else {
                Logger.error("Can not get properties info for type: \(type(of: object))")
                return nil
            }
            
            var mutableObject = object as! _ExtendCustomModelType
            let instanceIsNSObject = mutableObject.isNSObjectType()
            let head = mutableObject.headPointer()
            let bridegdProperty = mutableObject.getBridgePropertyLost()
            let propertyInfos = properties.map { PropertyInfo.init(key: $0.key, type: $0.type, address: head.advanced(by: $0.offset), bridged: instanceIsNSObject && bridegdProperty.contains($0.key)) }
            mutableObject.mapping(mapper: mapper)
            let requiredInfo = merge(children: children, propertyInfos: propertyInfos)
            return _serializeModelObject(instance: mutableObject, properties: requiredInfo, mapper: mapper) as Any
        default: return object.plainValue()
        }
    }
    
    static func _serializeModelObject(instance: _ExtendCustomModelType, properties: [String: (Any, PropertyInfo?)], mapper: Mapper) -> [String: Any] {
        var dict = [String: Any].init()
        for tuple in properties {
            var realKey = tuple.key
            var realValue = tuple.value.0
            if let info = tuple.value.1 {
                if info.bridged, let _value = (instance as! NSObject).value(forKey: tuple.key) { realValue = _value }
                if mapper.propertyExcluded(key: info.address.hashValue) { continue }
                if let mappingHandler = mapper.getMappingHandler(key: info.address.hashValue) {
                    if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 { realKey = mappingPaths[0].segments.last! }
                    if let transformer = mappingHandler.takeValueClosure {
                        if let _transformedValue = transformer(realValue) { dict[realKey] = _transformedValue }
                        continue
                    }
                }
            }
            
            if let typedValue = realValue as? _Transformable {
                if let result = self._serializeAny(object: typedValue) {
                    dict[realKey] = result
                    continue
                }
            }
            
            Logger.verbose("the value for key: \(tuple.key) is not transformable type")
        }
        
        return dict
    }
}
