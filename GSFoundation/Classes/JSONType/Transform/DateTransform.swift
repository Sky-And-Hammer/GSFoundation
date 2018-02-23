//
//  DateTransform.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of `Date` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< date <-- DateTransform()
///     }
open class DateTransform: TransformType {
    
    public func transformFromJSON(_ value: Any?) -> Date? {
        if let timeInt = value as? Double { return Date.init(timeIntervalSince1970: timeInt) }
        else if let timeString = value as? String { return Date.init(timeIntervalSince1970: atof(timeString)) }
        else { return nil }
    }
    
    public func transfromToJSON(_ value: Date?) -> Double? {
        return value?.timeIntervalSince1970 ?? nil
    }
}
