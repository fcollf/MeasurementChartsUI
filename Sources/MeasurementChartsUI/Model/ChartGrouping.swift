//
//  ChartGrouping.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 29/2/24.
//


import Charts
import Foundation
import SwiftUI


/// An enumeration defining the time-based grouping options for chart data.
///
/// This enum allows for the aggregation of chart data entries according to different time periods,
/// facilitating the visualization of data trends over daily, weekly, monthly, or yearly intervals.
///
@frozen
public enum ChartGrouping: Int, CaseIterable {
    
    
    case daily      = 1
    case weekly     = 2
    case monthly    = 3
    case yearly     = 4
    
}

    
// MARK: - Public Properties


public extension ChartGrouping {

    
    /// Provides a localized string description for each grouping option.
    var string: String {
        
        let key = String(format: "label.chart.grouping.%d", self.rawValue)
        let localizedStringResource = LocalizedStringResource(stringLiteral: key)
        
        return String(localized: localizedStringResource)
    }
    
    
    /// Determines the number of values to display simultaneously on the chart's X-axis,
    /// based on the selected time grouping.
    ///
    /// This property helps in configuring the chart to display an appropriate number of
    /// entries on the X-axis, enhancing readability and user experience. The values are
    /// predetermined for each grouping option to reflect typical use cases:
    ///
    /// - Daily: 24 hours
    /// - Weekly: 7 days
    /// - Monthly: Up to 31 days
    /// - Yearly: 12 months
    ///
    var xValueCount: Double {

        switch self {

            case .daily:    24
            case .weekly:   7
            case .monthly:  31
            case .yearly:   12
        }
    }
    
    
    /// Specifies the calendar component unit associated with each grouping option,
    /// to be used for determining the chart's X-axis values.
    ///
    /// This property aligns the chart's X-axis with calendar components, ensuring that
    /// data is grouped and displayed according to the appropriate time unit:
    /// - Daily: Hours
    /// - Weekly and Monthly: Days
    /// - Yearly: Months
    ///
    var xValueUnit: Calendar.Component {
        
        switch self {

            case .daily:    .hour
            case .weekly:   .day
            case .monthly:  .day
            case .yearly:   .month
        }
    }
    
    
    /// Determines the visible domain or range for the chart display in seconds, based on the selected time grouping.
    ///
    var xVisibleDomain: Int {
        
        switch self {
            case .daily:    24 * 3600
            case .weekly:   7 * 24 * 3600
            case .monthly:  31 * 24 * 3600
            case .yearly:   365 * 24 * 3600
        }
    }
    
    /// Specifies the components to which the chart aligns when scrolling stops, based on the selected time grouping.
    ///
    /// This property defines the alignment granularity of the chart's view when the user stops scrolling. It ensures
    /// that the chart aligns to significant and relevant time components, improving the readability and usability of
    /// the chart by snapping to logical points:
    ///
    /// - Daily: Aligns to the start of each hour.
    /// - Weekly and Monthly: Aligns to the start of each day.
    /// - Yearly: Aligns to the first day of each month.
    ///
    /// This alignment is particularly useful for temporal data, where it's beneficial for the user to see data points
    /// aligned to the start of logical time periods (e.g., the beginning of an hour or a day).
    ///
    var xScrollAlignment: DateComponents {
        
        switch self {
            case .daily: DateComponents(minute: 0)
            case .weekly, .monthly: DateComponents(hour: 0, minute: 0)
            case .yearly: DateComponents(day: 1)
        }
    }
    
}
