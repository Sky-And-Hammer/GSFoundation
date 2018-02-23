//
//  Metadata.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/11.
//

import Foundation

struct _class_rw_t {
    var flags: Int32
    var version: Int32
    var ro: UInt
    // other fields we don't care
    
    func class_ro_t() -> UnsafePointer<_class_ro_t>? { return UnsafePointer<_class_ro_t>(bitPattern: self.ro) }
}

struct _class_ro_t {
    var flags: Int32
    var instanceStart: Int32
    var instanceSize: Int32
    // other fields we don't care
}

// MARK: MetadataType

protocol MetadataType: PointerType {
    static var kind: Metadata.Kind? { get }
}

extension MetadataType {
    
    var kind: Metadata.Kind { return Metadata.Kind(flag: UnsafePointer<Int>(pointer).pointee) }
    
    init?(anyType: Any.Type) {
        self.init(pointer: unsafeBitCast(anyType, to: UnsafePointer<Int>.self))
        if let kind = type(of: self).kind, kind != self.kind { return nil }
    }
}

// MARK: Metadata

struct Metadata: MetadataType {
    
    var pointer: UnsafePointer<Int>
    init(type: Any.Type) {
        self.init(pointer: unsafeBitCast(type, to: UnsafePointer<Int>.self))
    }
}

internal struct _Metadata {}

fileprivate var is64BitPlatform: Bool {
    return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
}

// MARK: Metadata + Kind
// https://github.com/apple/swift/blob/swift-3.0-branch/include/swift/ABI/MetadataKind.def

extension Metadata {
    static let kind: Kind? = nil
    enum Kind {
        case `struct`
        case `enum`
        case optional
        case opaque
        case tuple
        case function
        case existential
        case metatype
        case objCClassWrapper
        case existentialMetatype
        case foreignClass
        case heapLocalVariable
        case heapGenericLocalVariable
        case errorObject
        case `class`
        init(flag: Int) {
            switch flag {
            case 1: self = .struct
            case 2: self = .enum
            case 3: self = .optional
            case 8: self = .opaque
            case 9: self = .tuple
            case 10: self = .function
            case 12: self = .existential
            case 13: self = .metatype
            case 14: self = .objCClassWrapper
            case 15: self = .existentialMetatype
            case 16: self = .foreignClass
            case 64: self = .heapLocalVariable
            case 65: self = .heapGenericLocalVariable
            case 128: self = .errorObject
            default: self = .class
            }
        }
    }
}

// MARK: Metadata + Class

extension Metadata {
    
    struct Class: NominalType {
        
        static let kind: Metadata.Kind? = .class
        var pointer: UnsafePointer<_Metadata._Class>
        
        var isSwiftClass: Bool { return self.pointer.pointee.databits & 1 == 1 }
        var nominalTypeDescriptorOffsetLocation: Int { return is64BitPlatform ? 8 : 11 }
        var superclass: Class? {
            guard let superclass = pointer.pointee.superclass else { return nil }
            // If the superclass doesn't conform to GSJSONType/GSJSONEnumType protocol,
            // we should ignore the properties inside
            if !(superclass is GSJSONType.Type) && !(superclass is GSJSONEnumType.Type) { return nil }
            guard let metaclass = Metadata.Class.init(anyType: superclass), metaclass.isSwiftClass else { return nil }
            return metaclass
        }
        
        func _propertyAndStartPoint() -> ([Property.Description], Int32?)? {
            let instanceStart = pointer.pointee.class_rw_t()?.pointee.class_ro_t()?.pointee.instanceStart
            var results = [Property.Description].init()
            if let properties = fetchProperties(nominalType: self) { results = properties }
            
            if let superclass = superclass,
                String.init(describing: unsafeBitCast(superclass.pointer, to: Any.Type.self)) != "SwiftObject",
                let superclassProperties = superclass._propertyAndStartPoint() {
                return (superclassProperties.0 + results, superclassProperties.1)
            }
            
            return (results, instanceStart)
        }
        
        func properties() -> [Property.Description]? {
            let propsAntStp = _propertyAndStartPoint()
            if let firstInstanceStart = propsAntStp?.1, let firstProperty = propsAntStp?.0.first {
                return propsAntStp?.0.map { Property.Description.init(key: $0.key, type: $0.type, offset: $0.offset - firstProperty.offset + Int(firstInstanceStart)) }
            } else { return propsAntStp?.0}
        }
    }
}

extension _Metadata {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
        var reserveword1: Int
        var reserveword2: Int
        var databits: UInt
        // other fields we don't care
        
        func class_rw_t() -> UnsafePointer<_class_rw_t>? {
            if is64BitPlatform {
                let fast_data_mask: UInt64 = 0x00007ffffffffff8
                let databits_t: UInt64 = UInt64(databits)
                return UnsafePointer<_class_rw_t>(bitPattern: UInt(databits_t & fast_data_mask)) }
            else { return UnsafePointer<_class_rw_t>(bitPattern: self.databits & 0xfffffffc) }
        }
    }
}

// MARK: Metadata + Struct

extension Metadata {
    
    struct Struct: NominalType {
        static var kind: Metadata.Kind? = .struct
        var pointer: UnsafePointer<_Metadata._Struct>
        var nominalTypeDescriptorOffsetLocation: Int { return 1 }
    }
}

extension _Metadata {
    struct _Struct {
        var kind: Int
        var nominalTypeDescriptorOffset: Int
        var parent: Metadata?
    }
}

// MARK: Metadata + ObjcClassWrapper

extension Metadata {
    
    struct ObjecClassWrapper: NominalType {
        static var kind: Metadata.Kind? = .objCClassWrapper
        var pointer: UnsafePointer<_Metadata._ObjecClassWrapper>
        var nominalTypeDescriptorOffsetLocation: Int { return is64BitPlatform ? 8 : 11 }
        var targetType: Any.Type? { return pointer.pointee.targetType }
    }
}

extension _Metadata {

    struct _ObjecClassWrapper {
        var kind: Int
        var targetType: Any.Type
    }
}
