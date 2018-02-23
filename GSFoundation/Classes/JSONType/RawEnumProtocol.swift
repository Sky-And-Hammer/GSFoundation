//
//  RawEnumProtocol.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

public protocol _RawEnumProtocol: _Transformable {
    
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}

public extension RawRepresentable where Self: _RawEnumProtocol {
    
    static func _transform(from object: Any) -> Self? {
        if let transformableType = RawValue.self as? _Transformable.Type, let typedValue = transformableType.transform(from: object) as? RawValue {
            return Self(rawValue: typedValue)
        } else { return nil }
    }
    
    func _plainValue() -> Any? { return self.rawValue}
}
