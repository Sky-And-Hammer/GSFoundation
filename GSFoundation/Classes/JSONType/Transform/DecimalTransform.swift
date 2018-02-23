//
//  DecimalTransform.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of `Decimal` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< decimal <-- DecimalTransform()
///     }
open class DecimalTransform: TransformType {
    
    public func transformFromJSON(_ value: Any?) -> Decimal? {
        guard let double = value as? Double else { return nil }
        return Decimal.init(double)
    }
    
    public func transfromToJSON(_ value: Decimal?) -> String? {
        return value?.description ?? nil
    }
}
