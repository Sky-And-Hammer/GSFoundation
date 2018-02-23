//
//  Measubale.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

typealias Byte = Int8

public protocol _Measurable {}
extension _Measurable {
    
    /// Locate the head of struct type object in memory
    mutating func headPointOfStruct() -> UnsafeMutablePointer<Byte> {
        return withUnsafePointer(to: &self) { UnsafeMutableRawPointer(mutating: $0).bindMemory(to: Byte.self, capacity: MemoryLayout<Self>.stride) }
    }
    
    /// Locate the head of class type object in memory
    mutating func headPointOfClass() -> UnsafeMutablePointer<Byte> {
        return UnsafeMutablePointer<Byte>(mutating: Unmanaged.passUnretained(self as AnyObject).toOpaque().bindMemory(to: Byte.self, capacity: MemoryLayout<Self>.stride))
    }
    
    /// Location the head of an object
    mutating func headPointer() -> UnsafeMutablePointer<Byte> {
        if Self.self is AnyClass { return headPointOfClass() }
        else { return headPointOfStruct() }
    }
    
    func isNSObjectType() -> Bool { return (type(of: self) as? NSObject.Type) != nil }
    
    func getBridgePropertyLost() -> Set<String> {
        guard let type = type(of: self) as? AnyClass else { return [] }
        return _getBridgePropertyList(anyClass: type)
    }
    
    func _getBridgePropertyList(anyClass: AnyClass) -> Set<String> {
        guard anyClass is GSJSONType else { return [] }
        var propertyList = Set<String>.init()
        if let superClass = class_getSuperclass(anyClass), superClass != NSObject.self {
            propertyList = propertyList.union(_getBridgePropertyList(anyClass: superClass))
        }
        
        let count = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        if let props = class_copyPropertyList(anyClass, count) {
            (0..<count.pointee).forEach { propertyList.insert(String.init(cString: property_getName(props.advanced(by: Int($0)).pointee))) }
        }
        
        return propertyList
    }
    
    static func size() -> Int { return MemoryLayout<Self>.size }
    static func align() -> Int { return MemoryLayout<Self>.alignment }
    static func offsetToAlignment(value: Int, align: Int) -> Int {
        let m = value & align
        return m == 0 ? 0 : align - m
    }
}


