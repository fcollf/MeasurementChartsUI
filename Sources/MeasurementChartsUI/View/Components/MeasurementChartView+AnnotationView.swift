//
//  MeasurementChartView+AnnotationView.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 23/2/24.
//


import Foundation
import SwiftUI


extension MeasurementChartView {
    
    
    /// A view for displaying detailed information about a selected data point in a chart.
    ///
    /// This view presents a selected measurement entry with formatting based on the chart's current
    /// grouping setting (daily, weekly, monthly, yearly).
    ///
    /// It shows the average value for the measurement and the date, formatted to match the grouping context
    ///
    struct AnnotationView: View {

        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
        
        
        /// The selected entry
        private let entry: GroupedChartDataEntry<U>

        /// Formatter for annotation dates.
        private var dateFormatter: DateFormatter {
            
            let formatter = DateFormatter()
            
            switch viewModel.grouping {
                
                case .daily:
                    formatter.dateFormat = "dd MMM yyyy, hh:mm"
                    
                case .weekly, .monthly:
                    formatter.dateFormat = "dd MMM yyyy"
                
                case .yearly:
                    formatter.dateFormat = "MMM yyyy"
            }

            return formatter
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes an `AnnotationView` with a specific measurement entry.
        ///
        /// - Parameters:
        ///   - entry: The selected measurement entry to display. This `GroupedChartDataEntry<U>` contains the data point's value(s) and date.
        ///
        /// The view automatically formats the measurement entry's average value and date according to the specified grouping,
        /// providing a contextual annotation for the selected chart data point
        ///
        init(_ entry: GroupedChartDataEntry<U>) {
            self.entry = entry
        }
        
        
        // MARK: - Body
        
        
        var body: some View {
            
            VStack(alignment: .leading) {
                
                if entry.count > 1 {
                    
                    Text("label.average")
                        .textCase(.uppercase)
                        .font(.caption.weight(.light))
                        .foregroundStyle(Color.secondary)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    
                    let value = viewModel.yAxisValueLabel(entry.average)
                    let unit = viewModel.yAxisValueLabel(entry.average, style: .unitOnly)
                    
                    Text(value)
                    Text(unit)
                        .textCase(.uppercase)
                        .font(.callout.smallCaps())
                        .foregroundStyle(Color.secondary)
                    
                }
                .textFieldStyle(.roundedBorder)
                .font(.title)
                .monospacedDigit()
                
                Text(entry.date, formatter: dateFormatter)
                    .font(.caption.weight(.light))
                    .textFieldStyle(.roundedBorder)
                    .foregroundStyle(Color.secondary)
                
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.secondary.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
            .fontDesign(.rounded)
        }

    }
}
