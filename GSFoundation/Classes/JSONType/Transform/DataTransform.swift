//
//  DataTransform.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of `Data` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< data <-- DataTransform()
///     }
open class DataTransform: TransformType {
    
    public init() {}
    
    public func transformFromJSON(_ value: Any?) -> Data? {
        guard let string = value as? String else { return nil }
        return Data.init(base64Encoded: string)
    }
    
    public func transfromToJSON(_ value: Data?) -> String? {
        return value?.base64EncodedString() ?? nil
    }
}
