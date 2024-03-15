//
//  Task+Delayed.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 29/2/24.
//


import Foundation


extension Task where Failure == Error {
    
    /// Schedules an asynchronous operation to be executed after a delay.
    ///
    /// This static method creates a new `Task` that begins by waiting for a specified time interval, then executes the provided asynchronous operation.
    ///
    /// - Parameters:
    ///   - delayInterval: The delay, in seconds, before starting the operation.
    ///   - priority: The priority of the task. If not specified, the task inherits the priority of the current context.
    ///   - operation: A closure that contains the asynchronous operation to execute after the delay.
    ///
    /// - Returns: A `Task` representing the delayed asynchronous operation. The task's `Success` type matches the return type of the `operation` closure.
    ///
    /// Example usage:
    /// ```
    /// let delayedTask = Task.delayed(byTimeInterval: 1.0) {
    ///     print("This prints after a 1 second delay.")
    ///     return true
    /// }
    /// ```
    ///
    /// You can later cancel the task if needed:
    /// ```
    /// delayedTask.cancel()
    /// ```

    static func delayed(
        byTimeInterval delayInterval: TimeInterval,
        priority: TaskPriority? = nil,
        operation: @escaping @Sendable () async throws -> Success
    ) -> Task {
        
        Task(priority: priority) {
            let delay = UInt64(delayInterval * 1_000_000_000)
            try await Task<Never, Never>.sleep(nanoseconds: delay)
            return try await operation()
        }
    }
}
