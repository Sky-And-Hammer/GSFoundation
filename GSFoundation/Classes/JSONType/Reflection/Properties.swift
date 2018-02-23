//
//  Properties.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/11.
//

import Foundation

struct Property {
    let key: String
    let value: Any
    
    struct Description {
        public let key: String
        public let type: Any.Type
        public let offset: Int
        
        public func write(_ value: Any, to storage: UnsafeMutableRawPointer) {
            return extensions(of: type).write(value, to: storage.advanced(by: offset))
        }
    }
}

/// Retrieve properties for `instance`
internal func getPropertie(forInstance instance: Any) -> [Property]? {
    if let props = getProperties(forType: type(of: instance)) {
        var copy = extensions(of: instance)
        let storag = copy.storage()
        return props.map { nextProperty(description: $0, storage: storag) }
    }
    
    return nil
}

private func nextProperty(description: Property.Description, storage: UnsafeRawPointer) -> Property {
    return Property.init(key: description.key, value: extensions(of: description.type).value(from: storage.advanced(by: description.offset)))
}

/// Retrieve property descriptions for `type`
internal func getProperties(forType type: Any.Type) -> [Property.Description]? {
    if let nominalType = Metadata.Struct.init(anyType: type) { return fetchProperties(nominalType: nominalType) }
    else if let nominalType = Metadata.Class.init(anyType: type) { return nominalType.properties() }
    else if let nominalType = Metadata.ObjecClassWrapper.init(anyType: type), let type = nominalType.targetType { return getProperties(forType: type) }
    else { return nil }
}

internal func fetchProperties<T: NominalType>(nominalType: T) -> [Property.Description]? { return propertiesFOrNominalType(nominalType) }
private func propertiesFOrNominalType<T: NominalType>(_ type: T) -> [Property.Description]? {
    guard let nominalTypeDescriptor = type.nominalTypeDescriptor else { return nil }
    guard nominalTypeDescriptor.numberOfFields != 0 else { return [] }
    guard let fieldTypes = type.fieldTypes, let fieldOffsets = type.fieldOffsets else { return nil }
    let fieldNames = nominalTypeDescriptor.fieldNames
    return (0..<nominalTypeDescriptor.numberOfFields).map { Property.Description.init(key: fieldNames[$0], type: fieldTypes[$0], offset: fieldOffsets[$0]) }
}



