//
//  BuiltlnBridgeType.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

protocol BuiltlbBridgeType: _Transformable {
    
    static func _transform(from object: Any) -> BuiltlbBridgeType?
    func _plainValue() -> Any?
}

extension NSString: BuiltlbBridgeType {
    
    static func _transform(from object: Any) -> BuiltlbBridgeType? {
        guard let string = String.transform(from: object) else { return nil }
        return NSString.init(string: string)
    }
    
    func _plainValue() -> Any? { return self }
}

extension NSNumber: BuiltlbBridgeType {
    static func _transform(from object: Any) -> BuiltlbBridgeType? {
        switch object {
        case let number as NSNumber: return number
        case let string as NSString:
            let lowercase = string.lowercased
            if lowercase == "true" { return NSNumber.init(value: true) }
            else if lowercase == "false" { return NSNumber.init(value: false) }
            else {
                return NumberFormatter.init().then { $0.numberStyle = .decimal }.number(from: string as String)
            }
        default:
            return nil
        }
    }
    
    func _plainValue() -> Any? { return self }
}

extension NSArray: BuiltlbBridgeType {
    
    static func _transform(from object: Any) -> BuiltlbBridgeType? { return object as? NSArray }
    func _plainValue() -> Any? { return (self as? Array<Any>)?.plainValue() }
}

extension NSDictionary: BuiltlbBridgeType {
    
    static func _transform(from object: Any) -> BuiltlbBridgeType? { return object as? NSDictionary }
    func _plainValue() -> Any? { return (self as? Dictionary<String, Any>)?.plainValue() }
}
