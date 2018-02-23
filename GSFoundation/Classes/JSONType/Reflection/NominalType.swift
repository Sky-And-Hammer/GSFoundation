//
//  NominalType.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/11.
//

import Foundation

protocol NominalType: MetadataType {
    var nominalTypeDescriptorOffsetLocation: Int { get }
}

extension NominalType {
    
    var nominalTypeDescriptor: NominalTypeDescriptor? {
        let p = UnsafePointer<Int>(pointer)
        let base = p.advanced(by: nominalTypeDescriptorOffsetLocation)
        if base.pointee == 0 { return nil } // swift class created dynamically in objc-runtime didn't have valid nominalTypeDescriptor
        return NominalTypeDescriptor.init(pointer: relativePointer(base: base, offset: base.pointee))
    }
    
    var fieldTypes: [Any.Type]? {
        guard let descriptor = nominalTypeDescriptor else { return nil }
        guard let function = descriptor.fieldTypesAccesspr else { return nil }
        return (0..<descriptor.numberOfFields).map { return unsafeBitCast(function(UnsafePointer<Int>(pointer)).advanced(by: $0).pointee, to: Any.Type.self)}
    }
    
    var fieldOffsets: [Int]? {
        guard let descriptor = nominalTypeDescriptor else { return nil }
        let vectorOffset = descriptor.fieldOffsetVector
        guard vectorOffset != 0 else { return nil }
        return (0..<descriptor.numberOfFields).map { return UnsafePointer<Int>(pointer)[vectorOffset + $0] }
    }
}

struct NominalTypeDescriptor: PointerType {
    
    var pointer: UnsafePointer<_NominalTypeDescriptor>
    
    var mangledName: String { return String.init(cString: relativePointer(base: pointer, offset: pointer.pointee.mangledName) as UnsafePointer<CChar>) }
    var numberOfFields: Int { return Int.init(pointer.pointee.numberofFields) }
    var fieldOffsetVector: Int { return Int.init(pointer.pointee.fieldOffsetVector) }
    var fieldNames: [String] { return Array.init(utf8Strings: relativePointer(base: UnsafePointer<Int32>(self.pointer).advanced(by: 3), offset: pointer.pointee.filedNames)) }
    
    typealias FieldsTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<UnsafePointer<Int>>
    var fieldTypesAccesspr: FieldsTypeAccessor? {
        let offset = pointer.pointee.filedTypesAccessor
        guard offset != 0 else { return nil }
        let p = UnsafePointer<Int32>(self.pointer)
        let offsetPointer: UnsafePointer<Int> = relativePointer(base: p.advanced(by: 4), offset: offset)
        return unsafeBitCast(offsetPointer, to: FieldsTypeAccessor.self)
    }
}

struct _NominalTypeDescriptor {
    var mangledName: Int32
    var numberofFields: Int32
    var fieldOffsetVector: Int32
    var filedNames: Int32
    var filedTypesAccessor: Int32
}
