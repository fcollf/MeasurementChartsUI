//
//  MeasurementChartView+ChartAreaView.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 1/3/24.
//


import Charts
import Foundation
import SwiftUI


/// A `PreferenceKey` for aggregating `CGSize` values to determine the maximum plot area size within a chart.
///
fileprivate struct PlotAreSizePreferenceKey: PreferenceKey {
    
    /// The data type used by the preference key
    typealias Value = CGSize
    
    /// The default value for the preference key
    static var defaultValue: Value = .zero
    
    /// Combines multiple `CGSize` values into a single value by storing the maximum width and height encountered.
    /// - Parameters:
    ///   - value: A reference to the current maximum `CGSize` value.
    ///   - nextValue: A closure that returns the next `CGSize` value to be considered.
    ///
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        
        value = CGSize(
            width: max(value.width, nextValue().width),
            height: max(value.height, nextValue().height))
    }
}


// MARK: - Chart Area


extension MeasurementChartView {
    
    
    struct ChartAreaView: View {
        
        
        // MARK: - Environment
        
        
        /// The environment object that provides the view model containing the state and logic
        @Environment(ViewModel.self) private var viewModel
        
        
        // MARK: - Private Properties
    
        
        /// Date  representing the currently selected data point within the chart, if any.
        @State private var rawSelection: Date? = nil
        
        /// Indicates whether the chart is currently being scrolled
        @State private var isScrolling: Bool = false
        
        /// Stores the current width of the chart
        @State private var chartWidth: CGFloat = 0.0
        
        /// Represents the y-axis scale for the chart
        @State private var yScale: ClosedRange<Double> = 0.0 ... 0.0
        
        /// A cancellable task used for managing y-axis associated updates
        @State private var yScaleTask: Task<Bool, Error>?
        
        /// Optional animation applied to transitions within the chart y-axis
        @State private var animation: Animation? = nil
        
        /// Computes and provides access to the currently selected measurement entry
        private var selection: GroupedChartDataEntry<U>? {
            viewModel[rawSelection]
        }
        
        /// Index identifying the currently visible page within the chart (center page)
        private let visiblePageIndex = 1
        
        /// Provides access to the data and configuration of the currently visible page within the chart
        private var visiblePage: ChartDataPage {
            viewModel.pages[visiblePageIndex]
        }
        
        
        // MARK: - Body
        
        
        var body: some View {
            
                
            GeometryReader { geometry in

                // Background Chart
                
                VStack(alignment: .leading) {
                    
                    if selection != nil {
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: geometry.size.height * 0.20)
                            .frame(maxWidth: .infinity)
                        
                    } else {
                        
                        HStack {
                            
                            AverageView(page: visiblePage)
                        }
                        .frame(height: geometry.size.height * 0.20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Chart {
                        
                        if let selection {
                            
                            RuleMark(
                                x: .value("label.date", selection.date, unit: viewModel.grouping.xValueUnit)
                            )
                            .lineStyle(StrokeStyle(lineWidth: 1.2))
                            .foregroundStyle(Color.secondary.opacity(0.3))
                            .zIndex(-1)
                            .annotation(
                                position: .top,
                                spacing: 0,
                                overflowResolution: .init(x: .fit(to: .plot), y: .disabled)
                            ) {
                                
                                AnnotationView(selection)
                                    .environment(viewModel)
                            }
                        }
                    }
                    .chartYScale(domain: yScale)
                    .chartYAxis {
                        
                        AxisMarks(values: viewModel.yValues) { value in
                            
                            AxisValueLabel {
                                
                                Text(viewModel.yAxisValueLabel(value))
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            AxisGridLine()
                        }
                    }
                    .chartXScale(domain: visiblePage.xScale)
                    .chartXAxis {
                        
                        AxisMarks(values: .stride(by: viewModel.grouping.xValueUnit, count: 1)) { value in
                            
                            AxisValueLabel {
                                
                                Text(viewModel.xAxisValueLabel(value))
                                    .foregroundStyle(Color.clear)
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .chartPlotStyle { content in
                        
                        content.background {
                            
                            GeometryReader { plotAreaProxy in
                                Color.clear
                                    .preference(key: PlotAreSizePreferenceKey.self, value: plotAreaProxy.size)
                            }
                        }
                    }
                    .onAppear {
                        
                        chartWidth = geometry.size.width * 0.9
                    }
                    .onPreferenceChange(PlotAreSizePreferenceKey.self) { size in
                        
                        chartWidth = min(size.width, geometry.size.width)
                    }
                }
                
                // Foreground Chart
                
                VStack(alignment: .leading) {
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: geometry.size.height * 0.20)
                        .frame(maxWidth: .infinity)
                    
                    ChartPagerView(isScrolling: $isScrolling) {
                        
                        ChartPageView(viewModel.pages[0])
                        
                        ChartPageView(viewModel.pages[1], rawSelection: $rawSelection)
                        
                        ChartPageView(viewModel.pages[2])
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: chartWidth, height: geometry.size.height)
                .clipped()
            }
            .onAppear {
                
                yScale = viewModel.yScale
            }
            .onChange(of: viewModel.grouping) {
                
                // Removes selection when changing grouping
                rawSelection = nil
                
                // Removes animation for the y-axis adjustment when changing the grouping
                animation = nil
            }
            .onChange(of: viewModel.yScale) {
                
                // Removes selection when scrolling
                rawSelection = nil

                // Check if there is a specified animation
                if let animation {
                    
                    // If there's an animation, delay the update and apply it with animation
                    yScaleTask?.cancel() 
                    
                    yScaleTask = Task.delayed(byTimeInterval: 0.2) {
                        
                        withAnimation(animation) {
                            yScale = viewModel.yScale
                        }
                        
                        return true
                    }
                    
                } else {
                    
                    // If there's no animation, update yScale immediately
                    yScale = viewModel.yScale
                    
                    // Apply animation for next yScale change
                    animation = .smooth
                }
            }
            .onChange(of: isScrolling) {
                
                // Remove selection when scrolling
                rawSelection = nil
            }
        }
    }
}



