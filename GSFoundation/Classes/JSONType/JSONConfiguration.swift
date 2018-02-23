//
//  JSONConfiguration.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/23.
//

import Foundation

public struct DeserializeOptions: OptionSet {
    
    public let rawValue: Int
    public static let caseInsensitive = DeserializeOptions(rawValue: 1 << 0)
    public static let caseUnderScore = DeserializeOptions(rawValue: 1 << 1)
    public static let defaultOptions: DeserializeOptions = []
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct GSJSONConfiguration {
    
    public static var deserializeOptions: DeserializeOptions = .defaultOptions
}
