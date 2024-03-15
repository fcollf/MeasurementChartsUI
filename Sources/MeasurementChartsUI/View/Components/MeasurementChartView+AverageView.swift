//
//  MeasurementChartView+AverageView.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 23/2/24.
//


import Foundation
import SwiftUI


extension MeasurementChartView {
    
    
    /// Displays the average measurement value and date range of the currently visible page in the chart.
    ///
    /// This view utilizes the provided `MeasurementChartPage` to display the average value of the measurements
    /// it contains, alongside a formatted date range that reflects the current grouping setting of the chart.
    /// 
    /// It's designed to be used within the chart's legend or as a supplementary view to provide users with
    /// contextual information about the displayed data.
    ///
    struct AverageView: View {
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
        
        
        /// The calendar used for date-related calculations
        private let calendar = Calendar.autoupdatingCurrent
        
        /// The date formatter
        private let formatter = DateFormatter()
        
        /// Represents the currently visible page in the chart,
        private let page: ChartDataPage
        
        /// The average measurement value for the visible page
        private let average: Measurement<U>?
        
        /// A computed property that formats the date range of the visible page into a string representation
        private var date: String {
            
            return switch viewModel.grouping {
                case .daily: formatDailyDate(from: page.xScale.lowerBound, to: page.xScale.upperBound)
                case .weekly: formatWeeklyDate(from: page.xScale.lowerBound, to: page.xScale.upperBound)
                case .monthly: formatMonthlyDate(from: page.xScale.lowerBound, to: page.xScale.upperBound)
                case .yearly: formatYearlyDate(from: page.xScale.lowerBound, to: page.xScale.upperBound)
            }
        }
        
        
        // MARK: - Private Methods
        
        
        /// Formats the start date for daily grouped data in the chart's legend.
        ///
        /// - Parameters:
        ///   - dateFrom: The start date of the data range.
        ///   - dateTo: The end date of the data range, not used for daily grouping.
        /// - Returns: A string formatted as "dd MMM yyyy" for the start date.
        ///
        private func formatDailyDate(from dateFrom: Date, to dateTo: Date) -> String {
            
            formatter.dateFormat = "dd MMM yyyy"
            
            return formatter.string(from: dateFrom)
        }
        
        
        /// Formats a date range into a string for weekly grouped data in the chart's legend.
        ///
        /// Depending on whether the start and end dates are in the same month or year, this method
        /// adjusts the format to provide the most relevant date range representation. It aims to
        /// minimize redundancy in the formatted string while providing clear context.
        ///
        /// - Parameters:
        ///   - dateFrom: The start date of the weekly range.
        ///   - dateTo: The end date of the weekly range.
        /// - Returns: A string representing the formatted date range.
        ///
        private func formatWeeklyDate(from dateFrom: Date, to dateTo: Date) -> String {
            
            let componentsFrom = calendar.dateComponents([.day, .month, .year], from: dateFrom)
            let componentsTo = calendar.dateComponents([.day, .month, .year], from: dateTo)
            
            formatter.dateFormat = "dd"
            
            if componentsFrom.month != componentsTo.month {
                formatter.dateFormat = "dd MMM"
            }
            
            if componentsFrom.year != componentsTo.year {
                formatter.dateFormat = "dd MMM yyyy"
            }
            
            let dateFromString = formatter.string(from: dateFrom)
            
            formatter.dateFormat = "dd MMM yyyy"
            
            let dateToString = formatter.string(from: dateTo)
            
            return "\(dateFromString) - \(dateToString)"
        }
        
        
        /// Formats a date range into a string for monthly grouped data.
        ///
        /// For dates within the same month and year, it returns the format "MMM yyyy". If the range spans different months
        /// within the same year, it adjusts to show day and month. For ranges spanning different years, it shows the full date.
        ///
        /// - Parameters:
        ///   - dateFrom: The start date of the monthly range.
        ///   - dateTo: The end date of the monthly range.
        /// - Returns: A string representing the formatted date range for the month.
        ///
        private func formatMonthlyDate(from dateFrom: Date, to dateTo: Date) -> String {
            
            let componentsFrom = calendar.dateComponents([.day, .month, .year], from: dateFrom)
            let componentsTo = calendar.dateComponents([.day, .month, .year], from: dateTo)
            
            formatter.dateFormat = "MMM yyyy"
            
            if componentsFrom.month == componentsTo.month {
                return formatter.string(from: dateFrom)
            }
            
            formatter.dateFormat = "dd MMM"
            
            if componentsFrom.year != componentsTo.year {
                formatter.dateFormat = "dd MMM yyyy"
            }
            
            let dateFromString = formatter.string(from: dateFrom)
            
            formatter.dateFormat = "dd MMM yyyy"
            
            let dateToString = formatter.string(from: dateTo)
            
            return "\(dateFromString) - \(dateToString)"
        }
        
        
        /// Formats a date range into a string suitable for yearly grouped data in the chart.
        ///
        /// This method outputs just the year for ranges within the same year. For ranges spanning multiple years,
        /// it provides a more detailed representation, showing the month and year of both the start and end dates.
        ///
        /// - Parameters:
        ///   - dateFrom: The start date of the yearly range.
        ///   - dateTo: The end date of the yearly range.
        /// - Returns: A string representing the formatted date range for yearly grouping.
        ///
        private func formatYearlyDate(from dateFrom: Date, to dateTo: Date) -> String {
            
            let componentsFrom = calendar.dateComponents([.day, .month, .year], from: dateFrom)
            let componentsTo = calendar.dateComponents([.day, .month, .year], from: dateTo)
            
            formatter.dateFormat = "yyyy"
            
            if componentsFrom.year == componentsTo.year {
                return formatter.string(from: dateFrom)
            }
            
            formatter.dateFormat = "MMM yyyy"
            
            let dateFromString = formatter.string(from: dateFrom)
            let dateToString = formatter.string(from: dateTo)
            
            return "\(dateFromString) - \(dateToString)"
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes the view with a specific page of measurement data.
        ///
        /// Sets up the view to display the average value from the provided `ChartDataPage`,
        /// which represents a collection of measurements within a specific timeframe or grouping in the chart.
        ///
        /// - Parameter page: The `ChartDataPage` containing the data to be displayed, including the average measurement value.
        ///
        init(page: ChartDataPage) {
            
            self.page = page
            self.average = page.average
        }
        
        
        // MARK: - Body
        
        
        var body: some View {
            
            VStack(alignment: .leading) {

                Text("label.average")
                    .font(.caption.uppercaseSmallCaps())
                    
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    
                    if let average, average.value != 0 {

                        let value = viewModel.yAxisValueLabel(average)
                        let unit = viewModel.yAxisValueLabel(average, style: .unitOnly)
                        
                        Text(value)
                            .fontWeight(.medium)
                        Text(unit)
                            .textCase(.uppercase)
                            .font(.callout)
                            .foregroundStyle(Color.secondary)
                        
                    } else {

                        Text("label.no-data")
                    }
                }
                .font(.largeTitle.monospacedDigit())

                HStack {
                    
                    Text(date)
                        .font(.callout)
                        .foregroundStyle(Color.secondary)

                }
            }
            .foregroundStyle(Color.primary)
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
