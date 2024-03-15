//
//  MeasurementChartView+ChartPageView.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 3/3/24.
//


import Charts
import Foundation
import SwiftUI


extension MeasurementChartView {
    
    
    struct ChartPageView: View {
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
        
        
        /// The index of the current page within the pager
        private let page: ChartDataPage
        
        /// A binding to the currently selected date, if any, allowing for interaction with the chart's selection mechanism.
        @Binding private var rawSelection: Date?
        
        /// Computes and provides access to the currently selected measurement entry
        private var selection: GroupedChartDataEntry<U>? {
            viewModel[rawSelection]
        }
        
        
        // MARK: - Initializer
        
        
        /// Initializes a `ChartPageView` with a given page index and a binding to the raw selection.
        ///
        /// - Parameters:
        ///   - page: The page data to display..
        ///   - rawSelection: A binding to an optional `Date` representing the current selection within the chart.
        ///
        init(_ page: ChartDataPage, rawSelection: Binding<Date?>) {
            
            self.page = page
            self._rawSelection = rawSelection
        }
        
        
        /// Initializes a `ChartPageView` with a given page index.
        ///
        /// - Parameters:
        ///   - page: The page data to display.
        ///
        init(_ page: ChartDataPage) {
            
            self.page = page
            self._rawSelection = .constant(nil)
        }
        
        
        // MARK: - Body
        
        
        var body: some View {
            
            Chart {
                
                ForEach(viewModel.entries) { entry in
                    
                    if let selection {
                        
                        PointMark(
                            x: .value("label.date", selection.date, unit: viewModel.grouping.xValueUnit),
                            y: .value("label.value", selection.value)
                        )
                        .foregroundStyle(viewModel.selectionForegroundStyle)
                        .symbol(viewModel.symbolShape)
                    }
                    
                    LineMark(
                        x: .value("label.date", entry.date, unit: viewModel.grouping.xValueUnit),
                        y: .value("label.value", entry.value)
                    )
                    .foregroundStyle(viewModel.foregroundStyle)
                    .symbol(viewModel.symbolShape)
                }
            }
            .chartPlotStyle { content in
                content.clipped()
            }
            .chartXSelection(value: $rawSelection)
            .chartYScale(domain: viewModel.yScale)
            .chartYAxis(.hidden)
            .chartXScale(domain: page.xScale)
            .chartXAxis {
                
                AxisMarks(values: .stride(by: viewModel.grouping.xValueUnit, count: 1)) { value in
                    
                    if viewModel.isAxisLimitMark(value) {
                        
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1.3))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                        
                        if viewModel.isAxisMark(value) {
                            
                            AxisTick()
                            
                            AxisValueLabel {
                                
                                Text(viewModel.xAxisValueLabel(value))
                            }
                        }
                        
                    } else {
                        
                        if viewModel.isAxisMark(value) {
                            
                            AxisGridLine(stroke: StrokeStyle(dash: [1, 3]))
                                .foregroundStyle(Color.secondary.opacity(0.25))
                            
                            AxisTick()
                            
                            AxisValueLabel {
                                
                                Text(viewModel.xAxisValueLabel(value))
                            }
                        }
                    }
                }
            }
            .chartGesture { proxy in
                
                SpatialTapGesture().onEnded { value in
                    proxy.selectXValue(at: value.location.x)
                }
            }
            .chartLegend(.hidden)
        }
    }
}
