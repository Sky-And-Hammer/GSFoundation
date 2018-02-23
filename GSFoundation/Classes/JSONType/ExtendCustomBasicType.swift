//
//  ExtendCustomBasicType.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/12.
//

import Foundation

public protocol _ExtendCustomBasicType: _Transformable {
    
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}
