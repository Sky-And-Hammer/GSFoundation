//
//  EnumTransform.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of 'ENUM' can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     enum EnumType: String {
///         case type1, type2
///     }
///
///     class BasicTypes: GSJSONType {
///         var type: EnumType?
///
///     func mapping(mapper: Mapper) {
///         mapper <<< type <-- EnumTransform()
///     }
///
///         required init() {}
///     }
open class EnumTransform<T: RawRepresentable>: TransformType {
    
    public init() {}
    
    public func transformFromJSON(_ value: Any?) -> T? {
        guard let raw = value as? T.RawValue else { return nil }
        return T(rawValue: raw)
    }
    
    public func transfromToJSON(_ value: T?) -> T.RawValue? {
        guard let object = value else { return nil }
        return object.rawValue
    }
}
