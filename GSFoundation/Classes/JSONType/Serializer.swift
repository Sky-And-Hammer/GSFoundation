//
//  Serializer.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/22.
//

import Foundation
import GSStability

public extension GSJSONType {
    
    public func toJSON() -> [String: Any]? {
        return Self._serializeAny(object: self) as? [String: Any] ?? nil
    }
    
    public func toJSONString(prettyPrint: Bool = false) -> String? {
        if let dict = toJSON() {
            guard JSONSerialization.isValidJSONObject(dict) else {
                Logger.warning("The \(dict) is not a valid JSON object")
                return nil
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: dict, options: prettyPrint ? [.prettyPrinted] : [])
                return String.init(data: data, encoding: .utf8)
            } catch {
                Logger.error(error.localizedDescription)
                return nil
            }
        } else { return nil }
    }
}

public extension Collection where Iterator.Element: GSJSONType {
    
    public func toJSON() ->[[String: Any]?] { return map { $0.toJSON() } }
    
    public func toJSONString(prettyPrint: Bool = false) -> String? {
        let dict = toJSON()
        guard JSONSerialization.isValidJSONObject(dict) else {
            Logger.warning("The \(dict) is not a valid JSON object")
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: prettyPrint ? [.prettyPrinted] : [])
            return String.init(data: data, encoding: .utf8)
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }   
    }
}
