//
//  MeasurementChartView+ViewModel.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 29/2/24.
//


import Charts
import Foundation
import SwiftUI


extension MeasurementChartView {
    

    /// Represents a segment or page of data in a chart.
    ///
    struct ChartDataPage {
        
        /// The page date
        var date: Date = .now
        
        /// Page scale for the X-Axis
        var xScale: ClosedRange<Date> = Date.now ... Date.now
        
        /// Average for entries in the page
        var average: Measurement<U>?
    }
    
    
    /// Manages the data and configuration for the `MeasurementChartView` and its sub-views.
    ///
    /// Supports dynamic data grouping, scale calculation, and formatting for both x and y axes based on user-selected
    /// grouping settings (daily, weekly, monthly, yearly). It handles the asynchronous loading of data, ensures that displayed data
    /// falls within specified date ranges, and prepares data for visualization across multiple pages to facilitate navigation and
    /// interaction with the chart.
    ///
    @Observable
    final class ViewModel {
        
        
        // MARK: - Types
        
        
        /// Defines the display style for measurement units in the chart.
        enum UnitStyle {
            
            case visible
            case hidden
            case unitOnly
            
        }
        
        
        // MARK: - Private Properties
        
        
        /// The calendar used for performing date calculations
        private var calendar = Calendar.autoupdatingCurrent
        
        
        // MARK: - Public Properties
        
        
        /// A measurement formatter configured for the current display settings.
        private var formatter: MeasurementFormatter {
            
            let formatter = MeasurementFormatter()
            
            formatter.unitOptions = .providedUnit
            formatter.unitStyle = .short
            
            formatter.numberFormatter.maximumFractionDigits = precision
            formatter.numberFormatter.minimumFractionDigits = precision
            
            return formatter
        }
        
        
        // MARK: - Public Properties
        
        
        /// The current method used to group chart data, affecting how data is aggregated and displayed
        var grouping: ChartGrouping = .weekly {
            
            didSet {
                update()
            }
        }
        
        /// The source data collection to be displayed in the chart
        var data: ChartDataCollection<Element>
        
        /// The processed entries ready for chart display, grouped according to the current `grouping` setting
        var entries: ChartDataCollection<G>
        
        /// An array representing pages of data in the chart, facilitating navigation through different time periods
        var pages: [ChartDataPage] = .init(repeating: .init(), count: 3)
        
        /// The date corresponding to the currently visible page in the chart
        var pageDate: Date = .now
        
        /// The unit of measurement used to display values in the chart
        var displayUnit: U
        
        /// The precision of the measurement values displayed in the chart, specified as the number of decimal places
        var precision: Int = 0
        
        /// The style applied to the foreground elements of the chart
        var foregroundStyle: AnyShapeStyle = .init(Color.indigo)
        
        /// The shape used for symbols in the chart, such as points representing data entries
        var symbolShape: AnyChartSymbolShape = .init(BasicChartSymbolShape.circle)
        
        /// The style applied to the foreground of the selected element of the chart
        var selectionForegroundStyle: AnyShapeStyle = .init(Color.teal.opacity(0.7))
        
        /// The closed range of numerical values representing the y-axis scale for the currently visible chart page
        var yScale: ClosedRange<Double> = 0 ... 0
        
        /// The values to display on the y-axis
        var yValues: [Double] = []
        
        
        // MARK: - Private Methods
        
        
        /// Calculates the key date for grouping measurement entries based on the current `grouping` setting.
        ///
        /// - Parameter date: The date to process.
        /// - Returns: A `Date` object adjusted to the start of the relevant grouping period.
        ///
        private func keyDate(for date: Date) -> Date {
            
            switch grouping {
                
                case .daily: calendar.startOfHour(for: date)
                case .weekly, .monthly: calendar.startOfDay(for: date)
                case .yearly: calendar.startOfMonth(for: date)
            }
        }
        
        
        /// Determines the page date for a given date according to the current `grouping` setting.
        ///
        /// - Parameter date: The date for which to find the corresponding page date.
        /// - Returns: The starting date of the page containing the given date.
        ///
        private func pageDate(for date: Date) -> Date {
            
            switch grouping {
                
                case .daily: calendar.startOfDay(for: date)
                case .weekly: calendar.startOfWeek(for: date)
                case .monthly: calendar.startOfMonth(for: date)
                case .yearly: calendar.startOfYear(for: date)
            }
        }
        
        
        /// Calculates the next page date from a given reference date, considering the current grouping value and an optional offset.
        ///
        /// - Parameters:
        ///   - date: The reference date from which to calculate the next page date.
        ///   - offset: The number of time periods to move from the reference date (either positive or negative).
        /// - Returns: The starting date of the next page, adjusted according to the specified offset and the current grouping method.
        ///
        private func nextPageDate(for date: Date, offset: Int = 0) -> Date {
            
            let pageDate = pageDate(for: date)
            
            return switch grouping {

                case .daily: calendar.date(byAdding: .day, value: 1 * offset, to: pageDate)!
                case .weekly: calendar.date(byAdding: .day, value: 7 * offset, to: pageDate)!
                case .monthly: calendar.date(byAdding: .month, value: 1 * offset, to: pageDate)!
                case .yearly: calendar.date(byAdding: .month, value: 12 * offset, to: pageDate)!
            }
        }
        
        
        /// Groups a collection of measurement entries within a specified date range according to the current `grouping` property.
        /// This method filters and organizes the entries to match the chart's grouping settings, considering only those entries that fall within the given date range.
        ///
        /// - Parameters:
        ///   - source: The collection of measurement entries to be grouped.
        ///   - range: The oprional date range within which to group the entries.
        /// - Returns: A collection of `GroupedChartDataEntry<U>` objects.
        ///
        private func group(_ source: ChartDataCollection<Element>, range: ClosedRange<Date>? = nil) -> ChartDataCollection<G> {
            
            // Temporary dictionary to hold the groups
            
            var groups: [Date: GroupedChartDataEntry<U>] = [:]
            
            // Process all measurements
            
            source.forEach { entry in
                
                if let range, !range.contains( entry.date ) {
                    return
                }
                
                let date = keyDate(for: entry.date)
                let measurement = entry.measurement.converted(to: displayUnit)
                
                if let group = groups[date] {
                    
                    // Insert the new measurement
                    group.insert(measurement)
                    
                    // Updates dictionary
                    groups[date] = group
                    
                } else {
                    
                    // Create a new group with the current measurement
                    groups[date] = GroupedChartDataEntry(date, measurement: measurement)
                }
            }
            
            // Returns the dictionary values
            return .init(contentsOf: groups.values)
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes the ViewModel with a source collection of entries and an optional grouping method, preparing it for use with the chart.
        ///
        /// - Parameters:
        ///   - data: The collection of measurement entries to be grouped and displayed in the chart.
        ///   - displayDate: Optional initial date to position the chart, if not provided display starts at the end of the chart.
        ///   - grouping: The method of grouping measurement entries for display, with a default of weekly grouping.
        ///
        init(_ data: ChartDataCollection<Element>, displayIn unit: U, displayAt date: Date? = nil, grouping: ChartGrouping = .weekly) {
            
            self.data = data
            self.entries = .init()
            self.displayUnit = unit
            self.grouping = grouping
            
            self.pageDate = pageDate(for: date ?? data.dateRange.upperBound)
        }
        
        
        // MARK: - Public Methods
        
        
        /// Accesses a `GroupedChartDataEntry<U>?` for a given date, if it exists.
        ///
        /// - Parameter date: The date for which to retrieve the corresponding grouped entry. If `nil`, the subscript returns `nil`.
        /// - Returns: A `GroupedChartDataEntry<U>?` that matches the provided date,
        /// or `nil` if no such entry exists or the date is `nil`.
        ///
        subscript(_ date: Date?) -> GroupedChartDataEntry<U>? {
            
            get {
                
                guard let date else { return nil }
                
                let keyDate = keyDate(for: date)
                let entry = entries.first { $0.date == keyDate }
                
                return entry
            }
        }
        
        
        ///Updates the chart data and prepares it for visualization.
        ///
        /// This method adjusts the chart data collection, ensures the `pageDate` is within allowable bounds, and regroups entries based on a specified date range. 
        /// It should be invoked whenever there's a need to refresh the chart's display, such as after a change in the visible date range or grouping criteria.
        ///
        /// - Parameter collection: An optional `ChartDataCollection` to replace the current data set. If nil, the existing data set is used.
        /// 
        func update(_ collection: ChartDataCollection<Element>? = nil) {
            
            // Updates the collection when needed
            if let collection {
                data = collection
            }
            
            // Makes sure the page date is within the global bounds
            pageDate = pageDate(for: pageDate.clamped(to: data.dateRange))

            // Gets the bounds needed to group the visible part of the chart
            let lowerBound = nextPageDate(for: pageDate, offset: -3)
            let upperBound = nextPageDate(for: pageDate, offset: 4)
    
            // Groups the entries
            
            entries = group(data, range: lowerBound...upperBound)
            
            yScale = yScale(for: entries)
            yValues = yValues(for: yScale)
            
            // Prepares the pages

            for i in -1...1 {

                let index = i + 1
                        
                let date = nextPageDate(for: pageDate, offset: i)
                let xScale = xScale(for: date)
                        
                pages[index].date = date
                pages[index].xScale = xScale
                pages[index].average = entries.filter { xScale.contains($0.date) }.average
            }
        }
        
        
        /// Calculates the y-axis scale for the chart given an array of grouped entries, with an option to allow negative values.
        ///
        /// This method determines the minimum and maximum values from the entries and applies a margin
        /// to create a more visually appealing scale. The inclusion of negative values can be controlled
        /// through the `allowNegativeValues` parameter. If allowing negatives, the scale adjusts to include
        /// both negative and positive values; otherwise, it ensures the scale starts from zero.
        ///
        /// - Parameters:
        ///   - entries: The `ChartDataCollection<G>` to calculate the y-axis scale.
        ///   - allowNegativeValues: A Boolean value that determines whether the scale should include negative values.
        /// - Returns: A `ClosedRange<Double>` representing the lower and upper bounds of the y-axis scale.
        ///
        func yScale(for entries: ChartDataCollection<G>, allowNegativeValues: Bool = true) -> ClosedRange<Double> {
            
            let minValue = entries.min?.value ?? 0.0
            let maxValue = entries.max?.value ?? 0.0
            
            // Calculates lower and upper bounds for the y-axis
            
            var lowerBound = (minValue - ( abs(minValue) * 0.25 )).rounded()
            var upperBound = (maxValue + ( abs(maxValue) * 0.25)).rounded()
            
            // Adjust bounds based on the allowNegativeValues flag
            
            if !allowNegativeValues {
                
                lowerBound = max(0.0, lowerBound)
                upperBound = max(0.0, upperBound)
            }
            
            // Ensure there's always a sensible range for the y-axis scale
            
            return if lowerBound <= upperBound {
                
                lowerBound ... upperBound
                
            } else {
                
                lowerBound ... max(0.0, lowerBound)
            }
        }
        
        
        /// Generates a set of values for labeling the y-axis of the chart within a specified scale.
        ///
        /// Given a closed range representing the y-axis scale, this method calculates intermediate values
        /// that can be used to label the y-axis at regular intervals. It ensures the labels cover the entire
        /// range of the scale, from the minimum to the maximum value.
        ///
        /// - Parameter yScale: A `ClosedRange<Double>` representing the scale of the y-axis.
        /// - Returns: An array of `Double` containing the minimum value, intermediate values, and maximum value
        ///   within the given yScale, suitable for axis labeling.
        ///
        func yValues(for yScale: ClosedRange<Double>) -> [Double] {
            
            let min = yScale.lowerBound
            let max = yScale.upperBound
            
            // Calculate the difference between max and min
            let range = max - min
            
            // Calculate intermediate values
            let firstThird = min + range / 3
            let secondThird = min + 2 * range / 3
            
            // Return the array containing min, intermediate values, and max
            return [min, firstThird, secondThird, max]
        }
        
        
        /// Calculates the x-axis scale for the chart based on a reference date and the current grouping setting.
        ///
        /// - Parameter date: The reference date around which to calculate the x-axis scale.
        /// - Returns: A `ClosedRange<Date>` representing the lower and upper bounds of the x-axis scale.
        ///
        func xScale(for date: Date) -> ClosedRange<Date>  {
            
            var lowerBound: Date
            var upperBound: Date
            
            switch grouping {
                    
                case .daily:
                    lowerBound = calendar.startOfDay(for: date)
                    upperBound = calendar.endOfDay(for: date)
                    
                case .weekly:
                    lowerBound = calendar.startOfWeek(for: date)
                    upperBound = calendar.endOfWeek(for: date)
                    
                case .monthly:
                    lowerBound = calendar.startOfMonth(for: date)
                    upperBound = calendar.endOfMonth(for: date)
                    
                case .yearly:
                    lowerBound = calendar.startOfYear(for: date)
                    upperBound = calendar.endOfYear(for: date)
            }
            
            return lowerBound...upperBound
        }
        
        
        /// Generates a series of dates to label the x-axis of the chart, based on the current grouping setting and a reference date.
        ///
        /// This method calculates the range of dates (x-axis scale) around the provided date according to the chart's grouping setting.
        /// It then populates an array with dates incrementing within this range by a unit appropriate to the grouping (e.g., hourly for daily,
        /// daily for weekly/monthly, and monthly for yearly groupings), ensuring the x-axis labels reflect the desired time granularity.
        ///
        /// - Parameter date: The reference date around which to generate the x-axis values.
        /// - Returns: An array of `Date` objects to label the x-axis, incrementing according to the current grouping setting.
        ///
        func xValues(for date: Date) -> [Date]  {
            
            var result: [Date] = .init()
            
            // Gets the scale
            let xScale = xScale(for: date)
            
            // First date
            var date = xScale.lowerBound
            
            // Creates the list of x-Axis values
            while date <= xScale.upperBound {
                
                result.append(date)
                
                // Next date acording to granularity
                
                date = switch grouping {
                    
                    case .daily: calendar.date(byAdding: .hour, value: 1, to: date)!
                    case .weekly, .monthly: calendar.date(byAdding: .day, value: 1, to: date)!
                    case .yearly: calendar.date(byAdding: .month, value: 1, to: date)!
                }
            }
            
            return result
        }
        
        
        // MARK: - Scrolling
        
        
        /// Checks if the pager can move to the given index.
        /// Ensures that the `xScale` of the page at the given index is completely contained within the `dateRange`.
        ///
        /// - Parameter index: The index to check for potential movement.
        /// - Returns: `true` if the movement to the specified index is possible, `false` otherwise.
        ///
        func canMove(to index: Int) -> Bool {
            pages[index].xScale.upperBound >= data.dateRange.lowerBound &&
            pages[index].xScale.lowerBound <= data.dateRange.upperBound
        }
        
        
        /// Notifies movement to the given page.
        /// - Parameter index: Page index.
        ///
        func didMove(to index: Int) {
            
            // Updates current date
            pageDate = pages[index].date
            
            // Updates center page
            pages[1] = pages[index]

            // Reloads the leading and trailing pages
            update()
        }
        
        
        // MARK: - Formatting
        
        
        /// Checks if the given axis value  is a limit date according to the selected granularity
        /// - Parameter value: The given ``AxisValue``.
        /// - Returns: `true` or `false`.
        ///
        func isAxisLimitMark( _ value: AxisValue) -> Bool {
            
            if let date = value.as(Date.self) {
                isAxisLimitMark(date)
            } else{
                false
            }
        }
        
        
        /// Checks if the given date is a limit date according to the selected granularity
        /// - Parameter date: The given date.
        /// - Returns: `true` or `false`.
        ///
        func isAxisLimitMark(_ date: Date) -> Bool {
            
            let calendar: Calendar = .current
            
            switch grouping {
                
                case.daily:
                    
                    let components =
                        calendar.dateComponents([.hour], from: date)
                    
                    return components.hour == 0
                    
                case .weekly:
                    
                    let components =
                        calendar.dateComponents([.weekday], from: date)
                    
                    return components.weekday == 2
                    
                case .monthly:
                    
                    let components =
                        calendar.dateComponents([.day], from: date)
                    
                    return ( components.day == 1 )
                    
                case .yearly:
                    
                    let components =
                        calendar.dateComponents([.month], from: date)
                    
                    return ( components.month == 1 )
            }
        }
        
        
        /// Checks if the given value needs to be shown at the axis.
        /// - Parameter date: The given axis value.
        /// - Returns: `true` or `false`.
        ///
        func isAxisMark( _ value: AxisValue) -> Bool {
            
            if let date = value.as(Date.self) {
                isAxisMark(date)
            } else {
                false
            }
        }
        
        
        /// Checks if the given date needs to be shown at the axis.
        /// - Parameter date: The given date.
        /// - Returns: `true` or `false`.
        ///
        func isAxisMark(_ date: Date) -> Bool {
            
            let calendar: Calendar = .current
            
            switch grouping {
                
                case .daily:
                    
                    let components = calendar.dateComponents([.hour], from: date)
                    
                    return components.hour?.isMultiple(of: 6) ?? false
                    
                case .weekly, .yearly:
                    
                    return true
                    
                case .monthly:
                    
                    let components = calendar.dateComponents([.weekday], from: date)
                    
                    return components.weekday == 2
            }
        }
        
        
        /// Formats the labels to show in the x-axis
        /// - Parameter value: The axis value.
        /// - Returns: The formatted date.
        ///
        func xAxisValueLabel(_ value: AxisValue) -> String {
            
            if let date = value.as(Date.self) {
                xAxisValueLabel(date)
            } else {
                ""
            }
        }
        
        
        /// Formats the labels to show in the x-axis
        /// - Parameter date: The given date
        /// - Returns: The formatted date.
        ///
        func xAxisValueLabel(_ date: Date) -> String {
            
            let formatter = DateFormatter()
            
            switch grouping {
                
                case .daily:
                    formatter.dateFormat = "HH"
                    
                case .weekly:
                    formatter.dateFormat = "EE"
                    
                case .monthly:
                    formatter.dateFormat = "dd"
                    
                case .yearly:
                    formatter.dateFormat = "MMM"
            }
            
            let string = formatter.string(from: date)
            
            return grouping == .yearly ? String(string.prefix(1)).uppercased() : string
        }
        
        
        /// Formats the labels to show in the y-axis
        /// - Parameter value: The axis value.
        /// - Returns: The formatted date.
        ///
        func yAxisValueLabel(_ value: AxisValue, style: UnitStyle = .hidden) -> String {
            
            if let value = value.as(Double.self) {
                yAxisValueLabel(value, style: style)
            } else {
                ""
            }
        }
        
        
        /// Formats the labels to show in the y-axis
        /// - Parameter value: The given value
        /// - Returns: The formatted date.
        ///
        func yAxisValueLabel(_ value: Double, style: UnitStyle = .hidden) -> String {
            
            let measurement = Measurement<U>(value: value, unit: displayUnit)
            
            return yAxisValueLabel(measurement, style: style)
        }
        
        
        /// Formats the labels to show in the y-axis
        /// - Parameter measurement: The given measurement
        /// - Returns: The formatted date.
        ///
        func yAxisValueLabel(_ measurement: Measurement<U>, style: UnitStyle = .hidden) -> String {
            
            let formatter = formatter
            
            let value = formatter.numberFormatter.string(from: NSNumber(value: measurement.value)) ?? "0"
            let unit = formatter.string(from: measurement.unit)
            
            return switch style {
                    
                case .visible: "\(value) \(unit)"
                case .hidden: value
                case .unitOnly: unit

            }
        }
        
    }
}



