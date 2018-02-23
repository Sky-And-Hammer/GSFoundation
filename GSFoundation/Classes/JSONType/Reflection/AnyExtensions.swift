//
//  AnyExtensions.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/11.
//

import Foundation

protocol AnyExtensions {}
extension AnyExtensions {
    
    static func isValueTypeOfSubtype(_ value: Any) -> Bool { return value is Self }
    static func value(from storage: UnsafeRawPointer) -> Any { return storage.assumingMemoryBound(to: self).pointee }
    static func write(_ value: Any, to storage: UnsafeMutableRawPointer) { guard let value = value as? Self else { return }; storage.assumingMemoryBound(to: self).pointee = value }
    static func takeValue(from anyValue: Any) -> Self? { return anyValue as? Self }
}

internal func extensions(of type: Any.Type) -> AnyExtensions.Type {
    struct Extensions: AnyExtensions {}
    var extensions: AnyExtensions.Type = Extensions.self
    withUnsafePointer(to: &extensions) { UnsafeMutableRawPointer(mutating: $0).assumingMemoryBound(to: Any.Type.self).pointee = type }
    return extensions
}

internal func extensions(of value: Any) -> AnyExtensions {
    struct Extensions: AnyExtensions {}
    var extensions: AnyExtensions = Extensions.init()
    withUnsafePointer(to: &extensions) { UnsafeMutableRawPointer(mutating: $0).assumingMemoryBound(to: Any.self).pointee = value }
    return extensions
}

/// Tests if `value` is `type` or a subclass of `type`
func value(_ value: Any, is type: Any.Type) -> Bool { return extensions(of: type).isValueTypeOfSubtype(value) }
/// Tests equality of any two existential types
func == (lhs: Any.Type, rhs: Any.Type) -> Bool { return Metadata(type: lhs) == Metadata(type: rhs) }

// MARK: AnyExtension + Storage

extension AnyExtensions {
    
    mutating func storage() -> UnsafeRawPointer {
        if type(of: self) is AnyClass { return UnsafeRawPointer(Unmanaged.passUnretained(self as AnyObject).toOpaque()) }
        else { return withUnsafePointer(to: &self) { UnsafeRawPointer($0) } }
    }
}
