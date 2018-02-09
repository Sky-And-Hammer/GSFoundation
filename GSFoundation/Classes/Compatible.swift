//
//  Compatible.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability

// MARK: - Compatible for Foundation
extension String: Compatible {}
extension Date: Compatible {}
extension DispatchQueue: Compatible {}
extension NotificationCenter: Compatible {}

// MARK: NotificationCenter

extension GS where Base: NotificationCenter {
    
    /// Convenience for 'addObserver(forName:object:queue:using:)'
    ///
    /// Use to add observer for a Notification.Name callback by a closure and doesn't need to run 'removeObserver(_:)' when deinit
    ///
    /// For example:
    ///
    ///     NotificationCenter.default.gs.addObserver(self, name: Notification.Name.gs.TableView.finishPull, object: nil) { (target, noti) in
    ///         target?.//do something
    ///     }
    ///
    /// - Parameters:
    ///   - observer: the receiver of notification. in closure, observer is weak reference
    ///   - name: the name of the notification for which to register the observer; that is, only notifications with this name are used to add the block to the operation queue.
    ///   - anObject: the object whose notifications the observer wants to receive; that is, only notifications sent by this sender are delivered to the observer.
    ///   - queue: the operation queue to which block should be added. If you pass nil, the block is run synchronously on the posting thread.
    ///   - handler: The block to be executed when the notification is received. The block is copied by the notification center and (the copy) held until the observer registration is removed
    /// - Returns: the object which is 'true' observer for NotificationCenter
    @discardableResult
    public func addObserver<T: AnyObject>(_ observer: T, name: Notification.Name, object anObject: AnyObject?, queue: OperationQueue? = OperationQueue.main, handler: @escaping (_ observer: T?, _ notification: Notification) -> Void) -> AnyObject {
        let observation = base.addObserver(forName: name, object: anObject, queue: queue) { [weak observer] noti in handler(observer, noti) }
        GSObserveationRemover.init(observation).makeRetainBy(observer)
        return observation
    }
}

private class GSObserveationRemover: NSObject {
    
    let observation: NSObjectProtocol
    
    init(_ obs: NSObjectProtocol) { observation = obs; super.init() }
    deinit { NotificationCenter.default.removeObserver(observation) }
    
    func makeRetainBy(_ owner: AnyObject) { GS_observationRemoversForObject(owner).add(self) }
}

private var kGSObservationRemoversForObject = "\(#file)+\(#line)"
private func GS_observationRemoversForObject(_ object: AnyObject) -> NSMutableArray {
    return objc_getAssociatedObject(object, &kGSObservationRemoversForObject) as? NSMutableArray ?? NSMutableArray.init().then {
        objc_setAssociatedObject(object, &kGSObservationRemoversForObject, $0, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: DispatchQueue

extension DispatchQueue {
    
    fileprivate static var _onceTracker = [String].init()
}

extension GS where Base: DispatchQueue {
    
    /// Safely to use 'DispatchQueue.queue.async {}' on any queue, it can check whether is main queue
    /// If is in main queue, the closure will execute immediately, other will execute asynchronously
    ///
    /// - Parameter block: the closure whick need to run
    public func safeAsync(_ block: @escaping () -> Void) {
        if base === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            base.async {
                block()
            }
        }
    }
    
    /// Convenience function to call 'dispatch_once' on the encapsulated closure.
    ///
    /// - Parameters:
    ///   - token: the tag marked as one for closure.
    ///   - block: the closure will run once
    static func once(token: String, block: ()-> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        guard Base._onceTracker.contains(token) else { return }
        Base._onceTracker.append(token)
        block()
    }
}

// MARK: String

extension GS where Base == String {
    
    /// Check 'self' is an URLString by regular expression '(http|https)://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$'
    public var isURL: Bool {
        return NSPredicate(format: "SELF MATCHES %@", "(http|https)://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$").evaluate(with:base)
    }
    
    /// Check 'self' is all numbers by 'Scanner'
    public var isAllDigit: Bool {
        var value: Int = 0
        let scanner = Scanner(string: base)
        return scanner.scanInt(&value) && scanner.isAtEnd
    }
    
    /// Check 'self' length are satisfied with size. use closed interval
    ///
    /// - Parameter tuple: the size of 'self' need to satisfy. less than 0 is not limited  like: (3, 6) or (-1, 12)
    /// - Returns: true is satified, false is not
    public func check(forLength tuple:(Int, Int)) -> Bool {
        guard tuple.0 <= tuple.1 || tuple.1 < 0 else { return false }
        return (tuple.0 < 0 ? true : base.count >= tuple.0) && (tuple.1 < 0 ? true : base.count <= tuple.1)
    }
    
    /// Returns a new string made by removing from both ends of the String characters contained whitespaces
    public func trimWhitespace() -> String {
        return base.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Date

//extension GS where Base == Date {
//    
//    /// 当前时间 + 指定时间
//    ///
//    /// - Parameters:
//    ///   - days: 日
//    ///   - hours: 小时
//    ///   - minutes: 分钟
//    ///   - seconds: 秒
//    /// - Returns: 新的时间
//    public func add(days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) -> Date? {
//        return NSCalendar.current.date(byAdding: DateComponents(days: days, hours: hours, minutes: minutes, seconds: seconds), to: base)
//    }
//    
//    /// 获取 当\(suffix)毫秒 时间戳
//    public static var currentMilliseconds: Int { return Int(Date.init().timeIntervalSince1970 * 1000) }
//    
//    /// 获取 对应的毫秒时间戳
//    public var milliseconds: Int { return Int(base.timeIntervalSince1970 * 1000) }
//    
//    /// 返回和当前时间比较的文字描述, like '1 天前'， '3 年后'
//    public var sinceNowDesc: String {
//        let now = Date.init()
//        let suffix = base.timeIntervalSince1970 < now.timeIntervalSince1970 ? "前" : "后"
//        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfYear, .month, .year], from: base, to: now)
//        if let year = components.year, year > 0 { return "\(year) 年\(suffix)"}
//        else if let month = components.month, month > 0 { return "\(month) 月\(suffix)" }
//        else if let week = components.weekOfYear, week > 0 { return "\(week) 周\(suffix)" }
//        else if let day = components.day, day > 0 { return "\(day) 天\(suffix)" }
//        else if let hour = components.hour, hour > 0 { return "\(hour) 小时\(suffix)" }
//        else if let min = components.minute, min > 0 { return "\(min) 分钟\(suffix)" }
//        else if let second = components.second, second >= 3 { return "\(second) 秒\(suffix)" }
//        else { return "刚刚" }
//    }
//    
//    /// 获取对应 周几, like '星期日'
//    public var weekDesc: String {
//        switch Calendar.current.component(Calendar.Component.weekday, from: base) {
//        case 0: return "星期日"
//        case 1: return "星期一"
//        case 2: return "星期二"
//        case 3: return "星期三"
//        case 4: return "星期四"
//        case 5: return "星期五"
//        case 6: return "星期六"
//        default: return _fatailError(value: String.init()) }
//    }
//    
//    /// 指定 formatter 进行转换
//    public func formatDesc(_ formater: DateFormatter) -> String { return formater.string(from: base) }
//}

