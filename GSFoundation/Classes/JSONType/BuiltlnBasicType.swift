//
//  BuiltlnBasicType.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation
import GSStability

protocol BuiltlnBasicType: _Transformable {
    
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}

extension BuiltlnBasicType {
    func _plainValue() -> Any? { return self }
}

protocol IntegerPropertyProtocol: FixedWidthInteger, BuiltlnBasicType {
    
    init?(_ text: String, radix: Int)
    init(_ number: NSNumber)
}

extension IntegerPropertyProtocol {
    
    static func _transform(from object: Any) -> Self? {
        switch object {
        case let string as String: return Self.init(string, radix: 10)
        case let number as NSNumber: return Self.init(number)
        default: return nil
        }
    }
}

extension Int: IntegerPropertyProtocol {}
extension UInt: IntegerPropertyProtocol {}
extension Int8: IntegerPropertyProtocol {}
extension Int16: IntegerPropertyProtocol {}
extension Int32: IntegerPropertyProtocol {}
extension Int64: IntegerPropertyProtocol {}
extension UInt8: IntegerPropertyProtocol {}
extension UInt16: IntegerPropertyProtocol {}
extension UInt32: IntegerPropertyProtocol {}
extension UInt64: IntegerPropertyProtocol {}

extension Bool: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> Bool? {
        switch object {
        case let string as NSString:
            let lowercase = string.lowercased
            if ["0", "false"].contains(lowercase) { return false }
            else if ["1", "true"].contains(lowercase) { return true }
            else { return nil }
        case let number as NSNumber: return number.boolValue
        default: return nil }
    }
}

protocol FloatPropertyProtocol: LosslessStringConvertible, BuiltlnBasicType {
    
    init(_ number: NSNumber)
}

extension FloatPropertyProtocol {
    
    static func _transform(from object: Any) -> Self? {
        switch object {
        case let string as String: return Self.init(string)
        case let number as NSNumber: return Self.init(number)
        default: return nil
        }
    }
}

extension Float: FloatPropertyProtocol {}
extension Double: FloatPropertyProtocol {}

extension String: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> String? {
        switch object {
        case let string as String: return string
        case let number as NSNumber:
            if NSStringFromClass(type(of: number)) == "__NSCFBoolean" { return number.boolValue ? "true" : "false" }
            else { return number.stringValue }
        case _ as NSNull: return nil
        default: return "\(object)"
        }
    }
}

extension Optional: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> Optional? {
        if let value = (Wrapped.self as? _Transformable.Type)?.transform(from: object) as? Wrapped { return Optional(value) }
        else if let value = object as? Wrapped { return Optional(value) }
        else { return nil }
    }
    
    func _getWrappedValue() -> Any? { return self.map { $0 as Any} }
    func _plainValue() -> Any? {
        if let value = _getWrappedValue() {
            if let transformable = value as? _Transformable { return transformable.plainValue() }
            else { return value }
        } else { return nil }
    }
}

extension ImplicitlyUnwrappedOptional: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> ImplicitlyUnwrappedOptional? {
        if let value = (Wrapped.self as? _Transformable.Type)?.transform(from: object) as? Wrapped { return ImplicitlyUnwrappedOptional.init(value) }
        else if let value = object as? Wrapped { return ImplicitlyUnwrappedOptional.init(value) }
        else { return nil }
    }
    
    func _plainValue() -> Any? {
        if let value = _getWrappedValue() {
            if let transformable = value as? _Transformable { return transformable.plainValue() }
            else { return value }
        } else { return nil }
    }
    
    private func _getWrappedValue() -> Any? { return self == nil ? nil : self }
}

extension Collection {
    
    static func _collectionTransform(from object: Any) -> [Iterator.Element]? {
        guard let arr = object as? [Any] else {
            Logger.warning("Expect object to be an array but it's not")
            return nil
        }
        
        typealias Element = Iterator.Element
        var result: [Element] = [Element].init()
        arr.forEach {
            if let element = (Element.self as? _Transformable.Type)?.transform(from: $0) as? Element { result.append(element) }
            else if let element = $0 as? Element { result.append(element) }
        }
        
        return result
    }
    
    func _collectionPlainValue() -> Any? {
        typealias Element = Iterator.Element
        var result: [Any] = [Any].init()
        self.forEach {
            if let transformable = $0 as? _Transformable, let transValue = transformable.plainValue() { result.append(transValue) }
            else { Logger.error("Value: \($0) isn't transformable type") }
        }
        
        return result
    }
}

extension Array: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> [Element]? { return self._collectionTransform(from: object) }
    func _plainValue() -> Any? { return self._collectionPlainValue() }
}

extension Set: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> Set<Element>? {
        if let arr = self._collectionTransform(from: object) { return Set.init(arr) }
        else { return nil }
    }
    
    func plainValue() -> Any? { return self._collectionPlainValue() }
}

extension Dictionary: BuiltlnBasicType {
    
    static func _transform(from object: Any) -> Dictionary<Key, Value>? {
        guard let dict = object as? [String: Any] else {
            Logger.warning("Expect obejct to be an NSDictionary but it's not")
            return nil
        }
        
        var result = [Key: Value].init()
        for (key, value) in dict {
            if let key = key as? Key {
                if let value = (Value.self as? _Transformable.Type)?.transform(from: value) as? Value { result[key] = value }
                else if let value = value as? Value { result[key] = value }
            }
        }
        
        return result
    }
    
    func _plainValue() -> Any? {
        var result = [String: Any].init()
        for (key, value) in self {
            if let key = key as? String {
                if let transformable = value as? _Transformable, let transValue = transformable.plainValue() {
                    result[key] = transValue
                }
            }
        }
        
        return result
    }
}
