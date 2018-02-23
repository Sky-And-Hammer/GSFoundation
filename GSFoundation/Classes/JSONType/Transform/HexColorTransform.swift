//
//  HexColorTransform.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

/// A type of `UIColor` can transform from or to JSON, you need to do is implementing an optional `mapping` function
///
/// For example:
///
///     func mapping(mapper: Mapper) {
///         mapper <<< color <-- HexColorTransform()
///     }
open class HexColorTransfrom: TransformType {
    
    #if os(iOS) || os(tvOS) || os(watchOS)
    public typealias Object = UIColor
    #else
    public typealias Object = NSColor
    #endif
    
    var prefix: Bool
    var alpha: Bool
    
    public init(prefixToJSON: Bool = false, alphaToJSON: Bool = false) {
        prefix = prefixToJSON
        alpha = alphaToJSON
    }
    
    public func transformFromJSON(_ value: Any?) -> Object? {
        guard let rgba = value as? String else { return nil }
        if rgba.hasPrefix("#") { return getColor(hex: String(rgba[rgba.index(rgba.startIndex, offsetBy: 1)...])) }
        else { return getColor(hex: rgba) }
    }
    
    public func transfromToJSON(_ value: Object?) -> String? {
        guard let value = value else { return nil }
        return hexString(color: value)
    }
    
    fileprivate func hexString(color: Object) -> String {
        let comps = color.cgColor.components!
        let r = Int(comps[0] * 255)
        let g = Int(comps[1] * 255)
        let b = Int(comps[2] * 255)
        let a = Int(comps[3] * 255)
        var hexString: String = ""
        if prefix {
            hexString = "#"
        }
        hexString += String(format: "%02X%02X%02X", r, g, b)
        
        if alpha {
            hexString += String(format: "%02X", a)
        }
        return hexString
    }
    
    fileprivate func getColor(hex: String) -> Object? {
        var red: CGFloat   = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat  = 0.0
        var alpha: CGFloat = 1.0
        
        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
            default:
                // Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8
                return nil
            }
        } else {
            // "Scan hex error
            return nil
        }
        #if os(iOS) || os(tvOS) || os(watchOS)
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        #else
            return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
        #endif
    }
    
}
