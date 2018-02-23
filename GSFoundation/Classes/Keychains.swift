//
//  Keychains.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability
import KeychainAccess

/// A struct for identfy the device, include an uuid and timestamp for initialized
public struct GSDeviceID: GSJSONType {
    
    var uuid: String
    var timestamp: Double
    
    public init() {
        uuid = UIDevice.current.identifierForVendor?.uuidString ?? "0IOS0UDID0NOT0FOUND"
        timestamp = Date.init().timeIntervalSince1970
    }
}

/// Represents a 'GSKeychainKey' with an associated generic value type confirming to the 'GSJSONType' protocol
///
///     static let someKey = Key<ValyeType>("someKey")
public struct GSKeychainKey<ValueType: GSJSONType> {
    
    fileprivate let key: String
    
    public init(_ key: String) { self.key = key }
}

/// Provides strongly typed values associated with the lifetime of an application. Apropriate for user perferences
public struct GSKeychain {

    fileprivate var keychain: Keychain

    /// Shared instanche of 'GSKeychain'. used for 'Bundle.main.bundleIdentifier' for service name
    public static let `default`: GSKeychain = {
        return GSKeychain.init(keychain: Keychain.init(service: Bundle.identifier))
    }()

    
    public var deviceId = GSKeychainKey<GSDeviceID>.init("GSKeychain.deviceId")

    public init(keychain: Keychain) { self.keychain = keychain; initialization() }

    private func initialization() {
        if self.keychain.service == Bundle.identifier {
            guard get(key: deviceId) == nil else { return }
            
            set(key: deviceId, value: GSDeviceID.init())
        } else {
            set(key: deviceId, value: GSKeychain.default.get(key: GSKeychain.default.deviceId))
        }
    }

    
    /// A function to delete allKeys, exclude the device id
    public func destory() {
        keychain.allKeys().forEach {
            if $0 != deviceId.key {
                do {
                    try keychain.remove($0)
                } catch {
                    Logger.error(error.localizedDescription)
                }
            }
        }
    }
}

public extension GSKeychain {
    /// Get the value in `ValueType` of the key in `GSKeychainKey` you given from Keychain. nil by not found
    ///
    /// - Parameter key: the key of value. nil by not found
    func get<ValueType>(key: GSKeychainKey<ValueType>) -> ValueType? { return ValueType.from(JSON: keychain[key.key]) }

    /// Save the value in `ValueType` of the key in `GSKeychainKey` you given to Keychain. nil value like delete
    ///
    /// - Parameters:
    ///   - key: the key of value
    ///   - value: the value for saven. nil for delete
    func set<ValueType>(key: GSKeychainKey<ValueType>, value: ValueType?) { keychain[key.key] = value?.toJSONString() }
}

