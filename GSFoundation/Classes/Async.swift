//
//  Async.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

// MARK: DSL for GCD queues

/// 'GCD' is a convenience enum with cases to get 'DispatchQueue' of different quality of service classes, as provided by `DispatchQueue.global` or `DispatchQueue` for main thread or a specific custom queue.
///
/// For example:
///
///     let mainQueue = GCD.main
///     let customQueue = GCD.custom(queue: aCustomQueue)
private enum GCD {
    case main, userInteractive, userInitiated, utility, background, custom(queue: DispatchQueue)
    
    var queue: DispatchQueue {
        switch self {
        case .main: return .main
        case .userInteractive: return .global(qos: .userInteractive)
        case .userInitiated: return .global(qos: .userInitiated)
        case .utility: return .global(qos: .utility)
        case .background: return .global(qos: .background)
        case .custom(let queue): return queue
        }
    }
}

// MARK: Async Struct

private class Reference<T> { var value: T? }
public typealias Async = AsyncClosure<Void, Void>

/// The 'Async' struct is handles an internally '@convention(block) () -> Swift.Void'
///
/// Chainable dispatch closure with GCD:
///
///     Async.background{
///         // run on background queue
///     }.main {
///         // run on main queue
///     }
///
/// All moderns queue classes:
///
///     Async.main {}
///     Async.userInteractive {}
///     Async.userInitiated {}
///     Async.utility {}
///     Async.background {}
///     Async.customQueue(aCustomQueue) {}
///
/// Dispatch closure after delay:
///
///     Async.main(after: seconds) {}
///
/// Cancel closure not yet dispatched
///
///     let closure = Async.background {
///         // some work
///     }
///     let closure2 = closure.background {
///         // some other work
///     }
///     Async.main {
///         closure.cancel() // first closure is not cancelled
///         closure2.cancel() // second closure is cancelled
///     }
///
/// Wait for block to finish:
///
///     let block = Async.background { // do stuff }
///     // do other stuff
///     // wait for "Do stuff" to finish
///     block.wait()
///     // do rest of stuff
///
/// See https://github.com/duemunk/Async
public struct AsyncClosure<In, Out> {
    
    public var output: Out? { return output_.value }
    
    // MARK: Private properties and init
    
    /// private property to hold internally on to a '@convention(closure) () -> Swift.Void'
    private let workItem: DispatchWorkItem
    private let input:Reference<In>?
    private let output_: Reference<Out>
    
    
    
    /// Private init that takes a '@convention(closure) () -> Swift.Void'
    ///
    /// - Parameters:
    ///   - workItem: workItem
    ///   - input: input
    ///   - output: output
    private init(_ workItem: DispatchWorkItem, input: Reference<In>? = nil, output: Reference<Out> = Reference()) {
        self.workItem = workItem
        self.input = input
        self.output_ = output
    }
    
    // MARK: Static methods
    
    /// Sends a closure to be run asynchronously on the main thread
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public static func main<O>(after seconds: Double? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .main)
    }
    
    /// Sends a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public static func userInteractive<O>(after seconds: Double? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .userInteractive)
    }
    
    /// Sends a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public static func userInitiated<O>(after seconds: Double? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .userInitiated)
    }
    
    /// Sends a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public static func utility<O>(after seconds: Double? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .utility)
    }
    
    /// Sends a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public static func background<O>(after seconds: Double? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .background)
    }
    
    /// Sends a closure to be run asynchronously on a custom queue
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public static func custom<O>(queue: DispatchQueue, after seconds: Double? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .custom(queue: queue))
    }
    
    // MARK: Private Static Methods
    
    /// Convenience for dispatch_async(). encapsulates the closure in a 'true' GCD closure using DISPATCH_closure_INHERIT_QOS_CLASS
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - closure: the closure that is to be passed to be run on the queue
    ///   - queue: the queue on whick the 'closure' is run
    /// - Returns: an 'Async' struct whick encapsulates the '@convention(closure) () -> Swift.Void'
    private static func async<O>(after seconds: Double? = nil, closure: @escaping () -> O, queue: GCD) -> AsyncClosure<Void, O> {
        let reference = Reference<O>()
        let workItem = DispatchWorkItem { reference.value = closure() }
        
        if let seconds = seconds { queue.queue.asyncAfter(deadline: .now() + seconds, execute: workItem) }
        else { queue.queue.async(execute: workItem) }
        
        // Wrap closure in a struct since @conveontion(closure) () -> Swift.Void can't be extended
        return AsyncClosure<Void, O>(workItem, output: reference)
    }
    
    // MARK: Instance Methods
    
    /// Sends the a closure to be run asynchronously on main thread, after the current closure has finished
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public func main<O>(after seconds: Double? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .main)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE, after the current closure has finished
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue
    /// - Returns: An 'Async' struct
    @discardableResult
    public func userInteractive<O>(after seconds: Double? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .userInteractive)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED, after the current closure has finished
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public func userInitiated<O>(after seconds: Double? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .userInitiated)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY, after the current closure has finished
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public func utility<O>(after seconds: Double? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .utility)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND, after the current closure has finished
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public func background<O>(after seconds: Double? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .background)
    }
    
    /// Sends the a closure to be run asynchronously on a custom queue, after the current closure has finished
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue
    /// - Returns: an 'Async' struct
    @discardableResult
    public func custom<O>(queue: DispatchQueue, after seconds: Double? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .custom(queue: queue))
    }
    
    /// Convenience function to call 'dispatch_block_cancel()' on the encapsulated closure.
    /// Cancel the current closure, if it hasn't already begun running to GCD
    ///
    /// For example:
    ///
    ///     let closure = Async.background {
    ///         // some work
    ///     }
    ///     let closure2 = closure.background {
    ///         // some other work
    ///     }
    ///     Async.main {
    ///         closure.cancel() // first closure is not cancelled
    ///         closure2.cancel() // second closure is cancelled
    ///     }
    public func cancel() { workItem.cancel() }
    
    /// Convenience function t call 'dispatch_block_wait()' on the excapsulated closure
    /// Waits for the current closure to finish, on any given thread
    ///
    /// - Parameter seconds: max seconds to wait for closure to finish, if value is 0.0, it uses DISPATCH_TIME_FOREVER, 0.0 by default
    @discardableResult
    public func wait(seconds: DispatchTimeInterval? = nil) -> DispatchTimeoutResult {
        let timeout = seconds.flatMap { DispatchTime.now() + $0 } ?? .distantFuture
        return workItem.wait(timeout: timeout)
    }
    
    // MARK: Private Instance Methods
    
    /// Convenience for 'dispatch_block_notify()' to
    ///
    /// - Parameters:
    ///   - seconds: after how many seconds the closure should be run
    ///   - chainingClosure: the closure that is to be passed to be run on the queue is to be passed to be run on the queue
    ///   - queue: the queue on whick the 'closure' is run
    /// - Returns: an 'Async' struct whick excapsulated the '@convention(closure) () -> Swift.Void', whick is called when the current closure has finished
    private func chain<O>(after seconds: Double? = nil, chainingClosure: @escaping (Out) -> O, queue: GCD) -> AsyncClosure<Out, O> {
        let reference = Reference<O>()
        let dispatchWorkItem = DispatchWorkItem { reference.value = chainingClosure(self.output_.value!) }
        
        let queue = queue.queue
        if let seconds = seconds { workItem.notify(queue: queue) { queue.asyncAfter(deadline: .now() + seconds, execute: dispatchWorkItem) } }
        else { workItem.notify(queue: queue, execute: dispatchWorkItem) }
        
        // See Async.async() for comments
        return AsyncClosure<Out, O>(dispatchWorkItem, input: self.output_, output: reference)
    }
}

// MARK: Apply - DSL for `dispatch_apply`

/// 'Apply' is an empty struct with convenience static functions to parallelize a for-loop, as provided by 'dispatch_apply'
///
/// For example:
///
///     Apply.background(100) { i in // call closure in parallel }
///
/// 'Apply' runs a closure multiple itmes, before returning. if you want run the block asynchronously from the current thread, wrap it in an 'Async' closure:
///
/// like:
///
///     Async.background {
///         Apply.background(100) { i in // calls closure in parallel asynchronously }
///     }
public struct Apply {
    
    /// Closure is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE. the closure is being passed an index parameter
    ///
    /// - Parameters:
    ///   - iterations: how many times the closure should be run. index provided to closure goes from '0..<iterations'
    ///   - closure: the closure that is to be passed to be run
    public static func userInteractive(_ iterations: Int, closure: @escaping (Int) -> ()) {
        GCD.userInteractive.queue.async { DispatchQueue.concurrentPerform(iterations: iterations, execute: closure) }
    }
    
    /// Closure is run any given amount of times on a queue with a quality of service of QOS_CLASS_USER_INITIATED. the closure is being passed an index parameter
    ///
    /// - Parameters:
    ///   - iterations: how many times the closure should be run. index provided to closure goes from '0..<iterations'
    ///   - closure: the closure that is to be passed to be run
    public static func userInitiated(_ iterations: Int, closure: @escaping (Int) -> ()) {
        GCD.userInitiated.queue.async { DispatchQueue.concurrentPerform(iterations: iterations, execute: closure) }
    }
    
    /// Closure is run any given amount of times on a queue with a quality of service of QOS_CLASS_UTILITY. the closure is being passed an index parameter
    ///
    /// - Parameters:
    ///   - iterations: how many times the closure should be run. index provided to closure goes from '0..<iterations'
    ///   - closure: the closure that is to be passed to be run
    public static func utility(_ iterations: Int, closure: @escaping (Int) -> ()) {
        GCD.utility.queue.async { DispatchQueue.concurrentPerform(iterations: iterations, execute: closure) }
    }
    
    /// Closure is run any given amount of times on a queue with a quality of service of QOS_CLASS_BACKGROUND. the closure is being passed an index parameter
    ///
    /// - Parameters:
    ///   - iterations: how many times the closure should be run. index provided to closure goes from '0..<iterations'
    ///   - closure: the closure that is to be passed to be run
    public static func background(_ iterations: Int, closure: @escaping (Int) -> ()) {
        GCD.background.queue.async { DispatchQueue.concurrentPerform(iterations: iterations, execute: closure) }
    }
    
    /// Closure is run any given amount of times on a custom queue. the closure is being passed an index parameter
    ///
    /// - Parameters:
    ///   - iterations: how many times the closure should be run. index provided to closure goes from '0..<iterations'
    ///   - closure: the closure that is to be passed to be run
    public static func custom(queue: DispatchQueue,_ iterations: Int, closure: @escaping (Int) -> ()) {
        GCD.custom(queue: queue).queue.async { DispatchQueue.concurrentPerform(iterations: iterations, execute: closure) }
    }
}

// MARK: AsuncGroup Struct

/// The 'AsyncGroup' struct facilitates working with groups of asynchronous closures. handles a internally 'dispatch_grout_t'
///
/// Multiple dispatch closure with GCD:
///
///     let group = AsyncGroup()
///     group.background {
///         //  run on background queue
///     }.utility {
///         //  run on utility queue, after the previous closure
///     }
///     group.wait()
///
/// All moderns queue classes:
///
///     group.main()
///     group.userInteractive()
///     group.userInitiated()
///     group.utility()
///     group.backgound()
///     group.custom(aCustomQueue)()
///
/// Wait for group to finish:
///
///     let group = AsyncGroup()
///     group.backgound { //  do stuff }
///     group.backgound { //  do other stuff in parallel }
///     // wait for both to finish
///     group.wait()
///     // do rest of stuff
public struct AsyncGroup {
    
    // MARK: Pirvate properties and init
    
    /// private property to internally on to a 'dispatch_group_t'
    private var group: DispatchGroup
    
    /// private init that takes a 'dispatch_group_t'
    public init() { group = DispatchGroup() }
    
    /// Convenience for 'dispatch_group_async()'
    ///
    /// - Parameters:
    ///   - closure: the closure that is to be passed to be run on the queue
    ///   - queue: the queue on whick the 'closure' is run
    private func async(closure: @escaping @convention(block) () -> Swift.Void, queue: GCD) { queue.queue.async(group: group, execute: closure) }
    
    /// Convenience for 'dispathc_group_enter()'. used to add custom closure to the current group
    public func enter() { group.enter() }
    
    /// Convenience for 'dispatch_group_leave()'. used to flag a custom added block is complete
    public func leave() { group.leave() }
    
    // MARK: Instance Methods
    
    /// Sends the a closure to be run asynchronously on the main queue. in the current group
    ///
    /// - Parameter closure: the closure that is to be passed to be run on the queue
    public func main(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .main)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INTERACTIVE. in the current group
    ///
    /// - Parameter closure: the closure that is to be passed to be run on the queue
    public func userInteractive(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .userInteractive)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_USER_INITIATED. in the current group
    ///
    /// - Parameter closure: the closure that is to be passed to be run on the queue
    public func userInitiated(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .userInitiated)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_UTILITY. in the current group
    ///
    /// - Parameter closure: the closure that is to be passed to be run on the queue
    public func utility(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .utility)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a quality of service of QOS_CLASS_BACKGROUND. in the current group
    ///
    /// - Parameter closure: the closure that is to be passed to be run on the queue
    public func background(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .background)
    }
    
    /// Sends the a closure to be run asynchronously on a queue with a custom queue. in the current group
    ///
    /// - Parameter closure: the closure that is to be passed to be run on the queue
    public func custom(queue: DispatchQueue, _ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .custom(queue: queue))
    }
    
    /// Convenience funciton to call 'dispatch_group_wait()' on the encapsulated closure.
    /// Waits for the current group to finish. on any given thread
    ///
    /// - Parameter seconds: max seconds to wait for closures to finish. if value is nil, it uses DISPATCH_TIME_FOREVER. nil by default
    @discardableResult
    public func wait(seconds: Double? = nil) -> DispatchTimeoutResult {
        let timeout = seconds.flatMap { DispatchTime.now() + $0 } ?? .distantFuture
        return group.wait(timeout: timeout)
    }
}

// MARK: - Extension for `qos_class_t`

/**
 Extension to add description string for each quality of service class.
 */
public extension qos_class_t {
    
    /**
     Description of the `qos_class_t`. E.g. "Main", "User Interactive", etc. for the given Quality of Service class.
     */
    var description: String {
        get {
            switch self {
            case qos_class_main(): return "Main"
            case DispatchQoS.QoSClass.userInteractive.rawValue: return "User Interactive"
            case DispatchQoS.QoSClass.userInitiated.rawValue: return "User Initiated"
            case DispatchQoS.QoSClass.default.rawValue: return "Default"
            case DispatchQoS.QoSClass.utility.rawValue: return "Utility"
            case DispatchQoS.QoSClass.background.rawValue: return "Background"
            case DispatchQoS.QoSClass.unspecified.rawValue: return "Unspecified"
            default: return "Unknown"
            }
        }
    }
}


// MARK: - Extension for `DispatchQueue.GlobalAttributes`

/**
 Extension to add description string for each quality of service class.
 */
public extension DispatchQoS.QoSClass {
    
    var description: String {
        get {
            switch self {
            case DispatchQoS.QoSClass(rawValue: qos_class_main())!: return "Main"
            case .userInteractive: return "User Interactive"
            case .userInitiated: return "User Initiated"
            case .default: return "Default"
            case .utility: return "Utility"
            case .background: return "Background"
            case .unspecified: return "Unspecified"
            }
        }
    }
}
