//
//  TransformType.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of someone can transform `Object` from or to `JSON`
public protocol TransformType {
    
    associatedtype Object
    associatedtype JSON
    
    /// Transfrom JSON to `Object`, nil by failure
    ///
    /// - Parameter value: `JSON` always
    func transformFromJSON(_ value: Any?) -> Object?
    
    /// Transform `Object` to 'JSON', nil by failure
    ///
    /// - Parameter value: 'Object' always
    func transfromToJSON(_ value: Object?) -> JSON?
}
