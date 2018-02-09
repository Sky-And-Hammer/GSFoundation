//
//  Time.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/2/9.
//

import Foundation

/// A protocol for representative time interval
public protocol TimeUnit {
    
    /// A value for 'TimeUnit' convert a time interval to an timestamp. the radix we used is 1 seconds
    static var toTimeIntervalRatio: Double { get }
}

/// The 'Interval' struct is handles a time duration used 'TimeUnit'
///
/// Use like:
///
///     let tenMinutes = 10.minutes
///     let twoHours = 2.hours
///
/// And perform basic arithmetic operations like:
///
///     let interval = 10.minutes + 15.seconds
///     let laterDate = Date.init() + 1.hours
///     let result = 50.minutes < 1.hour // will return true
///
/// Conver to another timeUnit like:
///
///     let seconds = 2.hours.inSeconds
///     let timeInterval: TimeInterval = seconds.timeInterval
///
/// If you need a new timeUnit, you can:
///
///     public enum Week: TimeUnit {
///         public static var toTimeIntervalRatio: Double { return 604800 }
///     }
///     extension Interval {
///         public var inWeeks: Interval<Week> { return converted() }
///     }
///     extension Int {
///         public var weeks: Interval<Week> { return Interval<Week>(Double(self))
///     }
///
/// Then:
///
///     let days = 2.weeks.inDays // will return 14
public struct Interval<Unit: TimeUnit> {
    
    public var value: Double
    public var timeInterval: TimeInterval { return value * Unit.toTimeIntervalRatio }
    
    public init(_ value: Double) { self.value = value }
    public init(timeInterval: TimeInterval) { self.init(timeInterval / Unit.toTimeIntervalRatio) }
}

extension Interval: Hashable {
    
    public var hashValue: Int { return timeInterval.hashValue }
    
    public static func ==(lhs: Interval<Unit>, rhs: Interval<Unit>) -> Bool { return lhs.value == rhs.value }
    public static func ==<OtherUnit>(lhs: Interval<Unit>, rhs: Interval<OtherUnit>) -> Bool { return lhs == rhs.converted() }
    public static func !=<OtherUnit>(lhs: Interval<Unit>, rhs: Interval<OtherUnit>) -> Bool { return lhs != rhs.converted() }
}

extension Interval {
    
    public static func <(lhs: Interval<Unit>, rhs: Interval<Unit>) -> Bool { return lhs.value < rhs.value }
    public static func <=(lhs: Interval<Unit>, rhs: Interval<Unit>) -> Bool { return lhs.value <= rhs.value }
    public static func >(lhs: Interval<Unit>, rhs: Interval<Unit>) -> Bool { return lhs.value > rhs.value }
    public static func >=(lhs: Interval<Unit>, rhs: Interval<Unit>) -> Bool { return lhs.value >= rhs.value }
    
    public static func <<OtherUnit>(lhs: Interval<Unit>, rhs: Interval<OtherUnit>) -> Bool { return lhs < rhs.converted() }
    public static func <=<OtherUnit>(lhs: Interval<Unit>, rhs: Interval<OtherUnit>) -> Bool { return lhs <= rhs.converted() }
    public static func ><OtherUnit>(lhs: Interval<Unit>, rhs: Interval<OtherUnit>) -> Bool { return lhs > rhs.converted() }
    public static func >=<OtherUnit>(lhs: Interval<Unit>, rhs: Interval<OtherUnit>) -> Bool { return lhs >= rhs.converted() }
}

public enum Day: TimeUnit { public static var toTimeIntervalRatio: Double { return 86400 } }
public enum Hour: TimeUnit { public static var toTimeIntervalRatio: Double { return 3600 } }
public enum Minute: TimeUnit { public static var toTimeIntervalRatio: Double { return 60 } }
public enum Second: TimeUnit { public static var toTimeIntervalRatio: Double { return 1 } }
public enum Millsecond: TimeUnit { public static var toTimeIntervalRatio: Double { return 0.001 } }
public enum Microsecond: TimeUnit { public static var toTimeIntervalRatio: Double { return 0.000001 } }
public enum Nanosecond: TimeUnit { public static var toTimeIntervalRatio: Double { return 1e-9 } }

extension TimeUnit {
    
    fileprivate static func conversionRate<OtherUnit: TimeUnit>(to otherTimeUnit: OtherUnit.Type) -> Double {
        return Self.toTimeIntervalRatio / OtherUnit.toTimeIntervalRatio
    }
}

public extension Interval {
    
    var inDays: Interval<Day> { return converted() }
    var inHours: Interval<Hour> { return converted() }
    var inSeconds: Interval<Second> { return converted() }
    var inMinutes: Interval<Minute> { return converted() }
    var inMillseconds: Interval<Millsecond> { return converted() }
    var inMicroseconds: Interval<Microsecond> { return converted() }
    var inNanoseconds: Interval<Nanosecond> { return converted() }
    
    func converted<OtherUnit: TimeUnit>(to otherTimeUnit: OtherUnit.Type = OtherUnit.self) -> Interval<OtherUnit> {
        return Interval<OtherUnit>(self.value * Unit.conversionRate(to: otherTimeUnit))
    }
}

public extension Double {
    
    var days: Interval<Day> { return Interval<Day>(self) }
    var hours: Interval<Hour> { return Interval<Hour>(self) }
    var minutes: Interval<Minute> { return Interval<Minute>(self) }
    var seconds: Interval<Second> { return Interval<Second>(self) }
    var millseconds: Interval<Millsecond> { return Interval<Millsecond>(self) }
    var microseconds: Interval<Microsecond> { return Interval<Microsecond>(self) }
    var nanoseconds: Interval<Nanosecond> { return Interval<Nanosecond>(self) }
}

public extension Int {
    
    var days: Interval<Day> { return Interval<Day>(Double(self)) }
    var hours: Interval<Hour> { return Interval<Hour>(Double(self)) }
    var minutes: Interval<Minute> { return Interval<Minute>(Double(self)) }
    var seconds: Interval<Second> { return Interval<Second>(Double(self)) }
    var millseconds: Interval<Millsecond> { return Interval<Millsecond>(Double(self)) }
    var microseconds: Interval<Microsecond> { return Interval<Microsecond>(Double(self)) }
    var nanoseconds: Interval<Nanosecond> { return Interval<Nanosecond>(Double(self)) }
}
