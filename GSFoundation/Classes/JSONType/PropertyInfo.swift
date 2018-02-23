//
//  PropertyInfo.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/11.
//

import Foundation

/// A struct to descript propety of any object or others 's instance
struct PropertyInfo {
    
    /// A key used string to descript property's name
    let key: String
    
    /// A type of propety
    let type: Any.Type
    
    /// An memory address of instance's property
    let address: UnsafeMutableRawPointer
    
    /// <#Description#>
    let bridged: Bool
}
