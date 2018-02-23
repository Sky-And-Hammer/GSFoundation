//
//  Deserializer.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/22.
//

import Foundation
import GSStability

public extension GSJSONType {
    
    public static func from(JSON dict: NSDictionary?, designatedPath: String? = nil) -> Self? { return from(JSON: dict as? [String: Any]) }
    public static func from(JSON dict: [String: Any]?, designatedPath: String? = nil) -> Self? { return JSONDescrializer<Self>.fromJSON(dict: dict) }
    public static func from(JSON: String?, designatedPath: String? = nil) -> Self? { return JSONDescrializer<Self>.fromJSON(json: JSON, designatedPath: designatedPath) }

    public mutating func update(from dict: [String: Any]?) { JSONDescrializer<Self>.update(object: &self, from: dict) }
    public mutating func update(from JSON: String?) { JSONDescrializer<Self>.update(object: &self, from: JSON) }
}

public extension Array where Element: GSJSONType {
    
    public static func from(array: NSArray?) -> [Element?]? { return from(array: array as? [Any]) }
    public static func from(array: [Any]?) -> [Element?]? { return JSONDescrializer<Element>.arrayFromJSON(array: array) }
    public static func from(JSON: String?, designatedPath: String? = nil) -> [Element?]? { return JSONDescrializer<Element>.arrayFromJSON(json: JSON, designatedPath: designatedPath) }
}

class JSONDescrializer<T: GSJSONType> {
    
    static func fromJSON(dict: [String: Any]?, designatedPath: String? = nil) -> T? {
        var targetDict = dict
        if let path = designatedPath { targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any] }
        if let _dict = targetDict { return T._transform(dict: _dict) as? T }
        else { return nil }
    }
    
    static func fromJSON(json: String?, designatedPath: String? = nil) -> T? {
        guard let _json = json else { return nil }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: _json.data(using: .utf8)!, options: .allowFragments)
            if let jsonDict = jsonObject as? [String: Any] {
                return self.fromJSON(dict: jsonDict, designatedPath: designatedPath)
            } else { return nil }
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }
    
    static func arrayFromJSON(array: [Any]?) -> [T?]? {
        guard let _arr = array else { return nil }
        return _arr.map { fromJSON(dict: $0 as? [String: Any]) }
    }
    
    static func arrayFromJSON(json: String?, designatedPath: String? = nil) -> [T?]? {
        guard let _json = json  else { return nil }
        do {
            if let jsonData = _json.data(using: .utf8) {
                let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
                if let jsonArray = getInnerObject(inside: jsonDict, by: designatedPath) as? [Any] {
                    return jsonArray.map { fromJSON(dict: $0 as? [String: Any]) }
                }
            }
            
            return nil
        } catch {
            Logger.error(error.localizedDescription)
            return nil
        }
    }
    
    static func update(object: inout T, from dict: [String: Any]?, designatedPath: String? = nil) {
        var targetDict = dict
        if let path = designatedPath { targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any] }
        if let _dict = targetDict { T._transform(dict: _dict, to: &object) }
    }
    
    static func update(object: inout T, from json: String?, designatedPath: String? = nil) {
        guard let _json = json  else { return }
        do {
            if let jsonData = _json.data(using: .utf8),
                let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any] {
                update(object: &object, from: jsonDict)
            }
        } catch {
            Logger.error(error.localizedDescription)
        }
    }
}

fileprivate func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
    var result: Any? = object
    var abort = false
    if let paths = designatedPath?.components(separatedBy: "."), paths.count > 0 {
        var next = object as? [String: Any]
        paths.forEach {
            if $0.trimmingCharacters(in: .whitespacesAndNewlines) == "" || abort { return }
            if let _next = next?[$0] {
                result = _next
                next = _next as? [String: Any]
            } else { abort = true }
        }
    }
    
    return abort ? nil : result
}

