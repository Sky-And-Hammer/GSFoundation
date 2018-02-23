//
//  Transformable.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

public protocol _Transformable: _Measurable {}
extension _Transformable {
    
    static func transform(from object: Any) -> Self? {
        if let typeObject = object as? Self { return typeObject }
        else {
            switch self {
            case let type as _ExtendCustomBasicType.Type: return type._transform(from: object) as? Self
            case let type as BuiltlbBridgeType.Type: return type._transform(from: object) as? Self
            case let type as BuiltlnBasicType.Type: return type._transform(from: object) as? Self
            case let type as _RawEnumProtocol.Type: return type._transform(from: object) as? Self
            case let type as _ExtendCustomModelType.Type: return type._transform(from: object) as? Self
            default: return nil 
            }
        }
    }
    
    func plainValue() -> Any? {
        switch self {
        case let type as _ExtendCustomBasicType: return type._plainValue()
        case let type as BuiltlbBridgeType: return type._plainValue()
        case let type as BuiltlnBasicType: return type._plainValue()
        case let type as _RawEnumProtocol: return type._plainValue()
        case let type as _ExtendCustomModelType: return type._plainValue()
        default: return nil
        }
    }
}
