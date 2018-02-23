//
//  URLTransform.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of `URL` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< url <-- URLTransform(shouldEncodeURLString: false)
///     }
open class URLTransform: TransformType {
    
    private let shouldEncodeURLString:  Bool
    
    public init(shouldEncodeURLString: Bool = true) { self.shouldEncodeURLString = shouldEncodeURLString }
    
    public func transformFromJSON(_ value: Any?) -> URL? {
        guard let urlString = value as? String else { return nil }
        guard !shouldEncodeURLString else { return URL.init(string: urlString) }
        guard let excapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL.init(string: excapedURLString)
    }
    
    public func transfromToJSON(_ value: URL?) -> String? {
        return value?.absoluteString ?? nil
    }
}
