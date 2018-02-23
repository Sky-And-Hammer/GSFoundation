//
//  DateFormatterTransform.swift
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
///         mapper <<< date <-- DateFormatterTransform.init(formatter: DateFormatter.init().then {
///             $0.dateFormat = "yyyy-MM-dd"
///         })
///     }
open class DateFormatterTransform: TransformType {
    
    private let formatter: DateFormatter
    
    public init(formatter: DateFormatter) { self.formatter = formatter }
    
    public func transformFromJSON(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        return formatter.date(from: dateString)
    }
    
    public func transfromToJSON(_ value: Date?) -> String? {
        guard let date = value else { return nil }
        return formatter.string(from: date)
    }
}

/// A type of `Date` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< date <-- IS09601DateTransform()
///     }
final public class IS09601DateTransform: DateFormatterTransform {
    
    public init() {
        super.init(formatter: DateFormatter.init().then {
            $0.locale = Locale.init(identifier: "en_US_POSIX")
            $0.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        })
    }
}

/// A type of `Date` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< date <-- CustomDateFormatTransform(formatString: "yyyy-MM-dd")
///     }
final public class CustomDateFormatterTransform: DateFormatterTransform {
    
    public init(formatString: String) {
        super.init(formatter: DateFormatter.init().then {
            $0.locale = Locale.init(identifier: "en_US_POSIX")
            $0.dateFormat = formatString
        })
    }
}
