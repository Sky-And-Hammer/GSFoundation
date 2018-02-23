//
//  Mapper.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

public typealias CustomMappingKeyValueTuple = (Int, MappingPropertyHandler)

struct MappingPath {
    
    var segments: [String]
    
    static func buildFrom(rawPath: String) -> MappingPath {
        let regex = try? NSRegularExpression.init(pattern: "(?<![\\\\])\\.")
        let results = regex?.matches(in: rawPath, range: NSRange.init(location: 0, length: rawPath.count)) ?? []
        var splitPoints = results.map { $0.range.location }
        var curPos = 0
        var pathArr = [String].init()
        splitPoints.append(rawPath.count)
        splitPoints.forEach {
            let start = rawPath.index(rawPath.startIndex, offsetBy: curPos)
            let end = rawPath.index(rawPath.startIndex, offsetBy: $0)
            let subPath = String.init(rawPath[start..<end]).replacingOccurrences(of: "\\.", with: ".")
            if !subPath.isEmpty { pathArr.append(subPath) }
            curPos = $0 + 1
        }
        
        return MappingPath.init(segments: pathArr)
    }
}

extension Dictionary where Key == String, Value: Any {
    
    func findValue(byPath: MappingPath) -> Any? {
        var currentDic: [String: Any]? = self
        var lastValue: Any?
        byPath.segments.forEach {
            lastValue = currentDic?[$0]
            currentDic = currentDic?[$0] as? [String: Any]
        }
        
        return lastValue
    }
}

/// A class to transform `Property` from or to `JSON`, use closure to do it 
public class MappingPropertyHandler {
    
    var mappingPaths: [MappingPath]?
    var assingmentClosure: ((Any?) -> (Any?))?
    var takeValueClosure: ((Any?) -> (Any?))?
    
    public init(rawPaths: [String]?, assingmentClosure: ((Any?) -> (Any?))?, takeValueClosure: ((Any?) -> (Any?))?) {
        let mappingPaths = rawPaths?.map { (path) -> MappingPath in
            guard GSJSONConfiguration.deserializeOptions != .defaultOptions else { return MappingPath.buildFrom(rawPath: path) }
            var key = path
            if GSJSONConfiguration.deserializeOptions.contains(.caseInsensitive) { key = key.lowercased() }
            if GSJSONConfiguration.deserializeOptions.contains(.caseUnderScore) { key = key.replacingOccurrences(of: "_", with: "") }
            
            return MappingPath.buildFrom(rawPath: key)
        }.filter { $0.segments.count > 0 }
        
        if let count = mappingPaths?.count, count > 0 { self.mappingPaths = mappingPaths }
        self.assingmentClosure = assingmentClosure
        self.takeValueClosure = takeValueClosure
    }
}

/// The `Mapper` let you customize the key mapping to JSON fields, or parsing method of any property. All you need to do is implementing an optional `mapping` function, do things in it.
///
/// Use like:
///
///     class Cat: HandyJSON {
///         var id: Int64!
///         var name: String!
///         var parent: (String, String)?
///         var friendName: String?
///
///         required init() {}
///
///         func mapping(mapper: HelpingMapper) {
///             // specify 'cat_id' field in json map to 'id' property in object
///             mapper <<<
///                 self.id <-- "cat_id"
///
///             // specify 'parent' field in json parse as following to 'parent' property in object
///             mapper <<<
///                 self.parent <-- TransformOf<(String, String), String>(fromJSON: { (rawString) -> (String, String)? in
///                     if let parentNames = rawString?.characters.split(separator: "/").map(String.init) {
///                         return (parentNames[0], parentNames[1])
///                     }
///                     return nil
///                 }, toJSON: { (tuple) -> String? in
///                     if let _tuple = tuple {
///                         return "\(_tuple.0)/\(_tuple.1)"
///                     }
///                     return nil
///                 })
///
///             // specify 'friend.name' path field in json map to 'friendName' property
///             mapper <<<
///                 self.friendName <-- "friend.name"
///         }
///     }
///
/// If you want to exclude property, you need use 'exclude' function or like this:
///
///     class NotHandyJSONType {
///         var dummy: String?
///     }
///
///     class Cat: HandyJSON {
///         var id: Int64!
///         var name: String!
///         var notHandyJSONTypeProperty: NotHandyJSONType?
///         var basicTypeButNotWantedProperty: String?
///
///         required init() {}
///
///         func mapping(mapper: HelpingMapper) {
///             mapper >>> self.notHandyJSONTypeProperty
///             mapper >>> self.basicTypeButNotWantedProperty
///         }
///     }
public class Mapper {
    
    private var mappingHandlers = [Int: MappingPropertyHandler].init()
    private var excludeProperties = [Int].init()
    
    internal func getMappingHandler(key: Int) -> MappingPropertyHandler? { return mappingHandlers[key] }
    internal func propertyExcluded(key: Int) -> Bool { return excludeProperties.contains(key) }
    
//    /// Specify field in json parse as following to object property in object
//    ///
//    /// - Parameters:
//    ///   - property: the property of object
//    ///   - name: the `JSON` field name
//    public func specify<T>(property: inout T, name: String) { specify(property: &property, name: name, converter: nil) }
//
//    /// Specify field in json parse as following to object property in object
//    ///
//    /// - Parameters:
//    ///   - property: the property of object
//    ///   - converter: the property conver closure
//    public func specify<T>(property: inout T, converter: @escaping (String) -> T) { specify(property: &property, name: nil, converter: converter) }
//
//    /// Specify field in json parse as following to object property in object
//    ///
//    /// - Parameters:
//    ///   - property: the property of object
//    ///   - name: the `JSON` field name
//    ///   - converter: the property conver closure
//    public func specify<T>(property: inout T, name: String?, converter: ((String) -> T)?) {
//        let pointer = withUnsafePointer(to: &property) { $0 }
//        let key = pointer.hashValue
//        let names = name == nil ? nil : [name!]
//        if let _converter = converter {
//            let assignmentClosure = { (jsonValue: Any?) -> Any? in
//                if let _value = jsonValue, let object = _value as? NSObject, let str = String.transform(from: object) {
//                    return _converter(str)
//                }
//                return nil
//            }
//
//            mappingHandlers[key] = MappingPropertyHandler.init(rawPaths: names, assingmentClosure: assignmentClosure, takeValueClosure: nil)
//        } else {
//            mappingHandlers[key] = MappingPropertyHandler.init(rawPaths: names, assingmentClosure: nil, takeValueClosure: nil)
//        }
//    }
//
//    /// If any non-basic property of a class/struct could not conform to `GSJSONType`/`GSJSONEnumType` or you just do not want to do the deserialization with it, you should exclude it in the mapping function.
//    ///
//    /// - Parameter property: the property excluded
//    public func exclude<T>(property: inout T) { _exclude(property: &property) }
    fileprivate func _exclude<T>(property: inout T) { excludeProperties.append(withUnsafePointer(to: &property) { return $0 }.hashValue) }
    fileprivate func addCustomMapping(key: Int, mappingInfo: MappingPropertyHandler) { mappingHandlers[key] = mappingInfo }
}

infix operator <--: LogicalConjunctionPrecedence

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - name: the custom property's name
public func <--<T>(property: inout T, name: String) -> CustomMappingKeyValueTuple { return property <-- [name] }

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - name: the custom property's name
public func <--<T>(property: inout T, names:[String]) -> CustomMappingKeyValueTuple {
    return (withUnsafePointer(to: &property) { $0 }.hashValue, MappingPropertyHandler.init(rawPaths: names, assingmentClosure: nil, takeValueClosure: nil))
}


/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object, tranformer: Transform) -> CustomMappingKeyValueTuple { return property <-- (nil, tranformer) }

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object, tranformer: (String?, Transform?)) -> CustomMappingKeyValueTuple {
    return property <-- (tranformer.0 == nil ? [] : [tranformer.0!], tranformer.1)
}

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let assignmentClosure = { (jsonValue: Any?) -> Transform.Object? in return transformer.1?.transformFromJSON(jsonValue) }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object { return transformer.1?.transfromToJSON(_value) }
        else { return nil }
    }
    
    return (withUnsafePointer(to: &property) { $0 }.hashValue, MappingPropertyHandler.init(rawPaths: transformer.0, assingmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object?, transformer: Transform) -> CustomMappingKeyValueTuple { return property <-- (nil, transformer) }

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object?, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple { return property <-- (transformer.0 == nil ? [] : [transformer.0!], transformer.1) }

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object?, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let assignmentClosure = { (jsonValue: Any?) -> Any? in return transformer.1?.transformFromJSON(jsonValue) }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object { return transformer.1?.transfromToJSON(_value) as Any }
        else { return nil }
    }
    
    return (withUnsafePointer(to: &property) { $0 }.hashValue, MappingPropertyHandler.init(rawPaths: transformer.0, assingmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object!, transformer: Transform) -> CustomMappingKeyValueTuple { return property <-- (nil, transformer) }

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object!, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple { return property <-- (transformer.0 == nil ? [] : [transformer.0!], transformer.1) }

/// Generate a CustomMappingKeyValueTuple for mapping
///
/// - Parameters:
///   - property: the property need mapping
///   - tranformer: the custom `TransformType`
public func <--<Transform: TransformType>(property: inout Transform.Object!, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let assignmentClosure = { (jsonValue: Any?) -> Any? in return transformer.1?.transformFromJSON(jsonValue) }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object { return transformer.1?.transfromToJSON(_value) as Any }
        else { return nil }
    }
    
    return (withUnsafePointer(to: &property) { $0 }.hashValue, MappingPropertyHandler.init(rawPaths: transformer.0, assingmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

infix operator <<<: AssignmentPrecedence

/// Add customMappingKeyValueTuple for property
public func <<<(mapper: Mapper, mapping: CustomMappingKeyValueTuple) { mapper.addCustomMapping(key: mapping.0, mappingInfo: mapping.1) }
/// Add customMappingKeyValueTuple for property
public func <<<(mapper: Mapper, mappings: [CustomMappingKeyValueTuple]) { mappings.forEach { mapper.addCustomMapping(key: $0.0, mappingInfo: $0.1) } }

infix operator >>>: AssignmentPrecedence

/// If any non-basic property of a class/struct could not conform to `GSJSONType`/`GSJSONEnumType` or you just do not want to do the deserialization with it, you should exclude it in the mapping function.
public func >>><T>(mapper: Mapper, property: inout T) { mapper._exclude(property: &property) }


