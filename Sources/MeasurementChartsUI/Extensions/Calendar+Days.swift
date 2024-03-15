//
//  Calendar+Days.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 29/2/24.
//


import Foundation


/// Provides additional functions for day calculation.
///
extension Calendar {
    
    
    /// Returns the last moment of a given day.
    /// - Parameter date: The date whose end is being calculated.
    /// - Returns: The end of the given day.
    ///
    func endOfDay(for date: Date) -> Date {
        self.date(byAdding: DateComponents(day: 1, second: -1), to: self.startOfDay(for: date))!
    }
    
    
    /// Returns the last moment of the week for a given date.
    /// - Parameter date: The date within the week whose end is being calculated.
    /// - Returns: The end of the week that contains the given date.
    ///
    func endOfWeek(for date: Date) -> Date {
        self.endOfDay(
            for: self.date(byAdding: DateComponents(day: 6), to: self.startOfWeek(for: date))!)
    }
    
    
    /// Returns the last moment of the month for a given date.
    /// - Parameter date: The date within the month whose end is being calculated.
    /// - Returns: The end of the month that contains the given date.
    ///
    func endOfMonth(for date: Date) -> Date {
        self.endOfDay(
            for: self.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth(for: date))!)
    }
    
    
    /// Returns the last moment of the year for a given date.
    /// - Parameter date: The date within the year whose end is being calculated.
    /// - Returns: The end of the year that contains the given date.
    ///
    func endOfYear(for date: Date) -> Date {
        
        var components = dateComponents([.year], from: date)
        
        components.month = 12
        components.day = 31
                
        return self.endOfDay(for: self.date(from: components)!)
    }
    
    
    /// Returns the start of the hour for a given date.
    /// - Parameter date: The specific date and time.
    /// - Returns: The date adjusted to the start of its hour (minute, second, and nanosecond set to 0).
    ///
    func startOfHour(for date: Date) -> Date {
        self.date(from: self.dateComponents([.year, .month, .day, .hour], from: date))!
    }
    
    /// Returns the first day of the week for a given date.
    /// - Parameter date: The date within the week.
    /// - Returns: The start of the week that contains the given date.
    ///
    func startOfWeek(for date: Date) -> Date {
        self.startOfDay(for: self.date(from: dateComponents([.weekOfYear, .yearForWeekOfYear], from: date))!)
    }
    
    
    /// Returns the first day of the month for a given date.
    /// - Parameter date: The date within the month.
    /// - Returns: The start of the month that contains the given date.
    ///
    func startOfMonth(for date: Date) -> Date {
        self.startOfDay(for: self.date(from: dateComponents([.month, .year], from: date))!)
    }
    
    
    /// Returns the first day of the year for a given date.
    /// - Parameter date: The date within the year.
    /// - Returns: The start of the year that contains the given date.
    ///
    func startOfYear(for date: Date) -> Date {
        
        var components = self.dateComponents([.day, .month, .year], from: date)
        
        components.day = 1
        components.month = 1
        
        return self.startOfDay(for: self.date(from: components)!)
    }
    
}
