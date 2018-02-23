//
//  TransformOf.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of Custom object can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     enum EnumType {
///         case type1, type2
///     }
///
///     class BasicTypes: HandyJSON {
///         var type: EnumType?
///
///         func mapping(mapper: HelpingMapper) {
///             mapper <<<
///                 type <-- TransformOf<EnumType, String>(fromJSON: { (rawString) -> EnumType? in
///                     if let _str = rawString {
///                         switch (_str) {
///                         case "type1":
///                             return EnumType.type1
///                         case "type2":
///                             return EnumType.type2
///                         default:
///                             return nil
///                         }
///                     }
///                     return nil
///                 }, toJSON: { (enumType) -> String? in
///                     if let _type = enumType {
///                         switch (_type) {
///                         case EnumType.type1:
///                             return "type1"
///                         case EnumType.type2:
///                             return "type2"
///                         }
///                     }
///                     return nil
///                 })
///         }
///
///         required init() {}
///     }
open class TransformOf<ObejctType, JSONType>: TransformType {
    
    private let fromJSON: (JSONType?) -> ObejctType?
    private let toJSON: (ObejctType?) -> JSONType?
    
    public init(fromJSON: @escaping (JSONType?) -> ObejctType?, toJSON: @escaping (ObejctType?) -> JSONType?) {
        self.fromJSON = fromJSON
        self.toJSON = toJSON
    }
    
    public func transformFromJSON(_ value: Any?) -> ObejctType? {
        return fromJSON(value as? JSONType)
    }
    
    public func transfromToJSON(_ value: ObejctType?) -> JSONType? {
        return toJSON(value)
    }
}
