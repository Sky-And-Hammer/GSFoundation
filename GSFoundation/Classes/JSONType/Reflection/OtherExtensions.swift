//
//  OtherExtensions.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/11.
//

import Foundation

protocol UTF8Initializable {
    init?(validatingUTF8: UnsafePointer<CChar>)
}

extension String: UTF8Initializable {}
extension Array where Element: UTF8Initializable {
    
    init(utf8Strings: UnsafePointer<CChar>) {
        var pointer = utf8Strings
        var strings = [Element].init()
        while let string = Element.init(validatingUTF8: pointer) {
            strings.append(string)
            while pointer.pointee != 0 { pointer.advanced() }
            pointer.advanced()
            guard pointer.pointee != 0 else { break }
        }
        
        self = strings
    }
}

extension Strideable { mutating func advanced() { self = advanced(by: 1) } }
extension UnsafePointer {
    init<T>(_ pointer: UnsafePointer<T>) { self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self) }
}

internal func relativePointer<T, U, V>(base: UnsafePointer<T>, offset: U) -> UnsafePointer<V> where U: FixedWidthInteger {
    return UnsafeRawPointer(base).advanced(by: Int.init(offset)).assumingMemoryBound(to: V.self)
}
