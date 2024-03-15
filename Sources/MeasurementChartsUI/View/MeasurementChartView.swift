//
//  MeasurementChartView.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 23/2/24.
//


import Charts
import CoreData
import Foundation
import SwiftUI


/// A `MeasurementChartView` displays a chart based on a sequence of measurement entries.
///
/// This view is designed to visualize measurements that conform to a specific `Unit` and are represented by a
/// conforming `ChartDataEntry`. It supports dynamic grouping, selection, and display customization through its properties.
///
/// - Parameters:
///   - S: A sequence of measurement entries to be displayed in the chart.
///   - U: The unit of measurement conforming to `Dimension` used in the chart.
///   - Element: The type of measurement entry conforming to `ChartDataEntry` used to represent each data point in the chart.
/// - Constraints:
///   - `M.U` must be the same type as `U`, ensuring the measurement entries use the same unit of measurement as specified for the chart.
///   - `S.Element` must be of type `Element`, ensuring the collection consists of the correct measurement entries.

public struct MeasurementChartView<S: Sequence, U: Dimension, Element: ChartDataEntry>: View where Element.U == U, S.Element == Element {
    
    
    // MARK: Types
    
    
    /// Short name for `GroupedChartDataEntry<U>`.
    internal typealias G = GroupedChartDataEntry<U>
    
    
    // MARK: - Private Properties
    
    
    @State private var viewModel: ViewModel?
    
    /// The current grouping strategy for measurements in the chart
    @State private var grouping: ChartGrouping
    
    /// The currently selected date
    private let displayDate: Date?
    
    /// The collection of measurement entries used to populate the chart
    private let data: ChartDataCollection<Element>
    
    /// Optional header
    private let headerView: AnyView?
    
    /// The visibility of the grouping picker
    private var isGroupingPickerVisible: Bool = true
    
    /// The  unit of measurement to display in the chart
    private var displayUnit: U 
    
    /// The precision of the measurement values displayed in the chart, specified as the number of decimal places
    private var precision: Int = 0
    
    /// The style applied to the foreground elements of the chart
    private var foregroundStyle: AnyShapeStyle = .init(Color.indigo)
    
    /// The shape used for symbols in the chart
    private var symbolShape: AnyChartSymbolShape = .init(BasicChartSymbolShape.circle)
    
    /// The style applied to the foreground of the selected element of the chart
    private var selectionForegroundStyle: AnyShapeStyle = .init(Color.teal.opacity(0.7))
    
    
    // MARK: - Private Methods
    
    
    /// Initializes and configures a new `ViewModel` instance with the current data.
    ///
    /// - Returns: A fully configured `ViewModel` instance ready for use in rendering the `MeasurementChartView`.
    ///
    private func getViewModel() -> ViewModel {
        
        let viewModel = ViewModel(data, displayIn: displayUnit, displayAt: displayDate, grouping: grouping)
        
        // Updates display properties
        
        viewModel.precision = precision
        viewModel.foregroundStyle = foregroundStyle
        viewModel.symbolShape = symbolShape
        viewModel.selectionForegroundStyle = selectionForegroundStyle
        
        return viewModel
    }

    
    // MARK: - Initializer
    
    
    /// Initializes a new instance of `MeasurementChartView` with the specified measurements source 
    /// and optional initial date selection.
    ///
    /// - Parameters:
    ///   - source: The collection of measurement entries to display in the chart.
    ///   - date: An optional date to initially select in the chart. Defaults to nil for no initial selection.
    ///   - grouping: The method of grouping measurement entries for display, with a default of weekly grouping.
    ///
    public init(_ data: S, displayIn unit: U, displayAt date: Date? = nil, grouping: ChartGrouping = .weekly) {
        
        self.data = .init(contentsOf: data)
        self.displayUnit = unit
        self.displayDate = date
        self.grouping = grouping
        self.headerView = nil
    }
    
    
    /// Initializes a new instance of `MeasurementChartView` with the specified measurements source
    /// and optional initial date selection.
    ///
    /// - Parameters:
    ///   - source: The sequence of measurement entries to display in the chart.
    ///   - date: An optional date to initially select in the chart. Defaults to nil for no initial selection.
    ///   - grouping: The method of grouping measurement entries for display, with a default of weekly grouping.
    ///
    public init<V: View>(_ data: S, displayIn unit: U, displayAt date: Date? = nil, grouping: ChartGrouping = .weekly, @ViewBuilder _ header: () -> V) {

        self.data = .init(contentsOf: data)
        self.displayUnit = unit
        self.displayDate = date
        self.grouping = grouping
        self.headerView = AnyView(header())
    }
    
    
    // MARK: - Body
    
    
    public var body: some View {
        
        VStack(alignment: .leading) {
            
            // Grouping
            
            if isGroupingPickerVisible, !data.isEmpty {
                
                Picker("label.show-all", selection: $grouping) {
                    ForEach(ChartGrouping.allCases, id: \.self) {
                        Text($0.string)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top)
            }
            
            // Chart Area
            
            if let viewModel {
                
                if data.isEmpty {
                    
                    ContentUnavailableView("label.no-data", systemImage: "circle.slash")
                        .transition(.opacity)
                    
                } else {
                    
                    if let headerView {
                        headerView
                    }
                    
                    ChartAreaView()
                        .environment(viewModel)
                }
            }
        }
        .onAppear {
            
            viewModel = getViewModel()
        }
        .onChange(of: grouping) {
            
            viewModel?.grouping = grouping
        }
        .onChange(of: data) {
            
            viewModel?.update(data)
        }
    }
}


// MARK: - View Modifiers


public extension MeasurementChartView {
    
    
    /// Controls the visibility of the grouping picker by specifying whether it should be hidden.
    ///
    /// Use this modifier to hide or show the grouping picker in the chart view. Hiding the picker can be useful for
    /// scenarios where the grouping is predefined and should not be changed by the user.
    ///
    /// - Parameter bool: A Boolean value that determines whether the grouping picker is hidden (`true`) or visible (`false`).
    /// - Returns: A `MeasurementChartView` instance with the modified visibility state for the grouping picker.
    ///
    func groupingPickerHidden(_ bool: Bool = true) -> Self {
        var view = self
        view.isGroupingPickerVisible = !bool
        return view
    }
    
    
    /// Sets the precision for measurement values in the chart.
    ///
    /// This modifier allows you to specify the number of decimal places to use for the measurement values displayed in the chart.
    /// It enables you to control the granularity of the data presentation.
    ///
    /// - Parameter decimals: The number of decimal places for the measurement values.
    /// - Returns: A `MeasurementChartView` instance with the specified precision.
    ///
    func precision(_ decimals: Int) -> Self {
        
        var view = self
        view.precision = decimals
        return view
    }
    
    
    /// Applies a foreground style to the chart elements.
    ///
    /// This modifier allows you to customize the appearance of the foreground elements in the chart,
    /// such as lines and symbols, by applying the specified shape style.
    ///
    /// - Parameters:
    ///    - style: The shape style to apply to the chart's foreground elements.
    ///    - selection: The shape style to apply to the chart's foreground selected element.
    /// - Returns: A `MeasurementChartView` instance with the applied foreground style.
    ///
    func foregroundStyle<T>(_ style: T, selection: T? = nil) -> Self where T: ShapeStyle {
        var view = self
        view.foregroundStyle = AnyShapeStyle(style)
        view.selectionForegroundStyle = AnyShapeStyle(selection ?? style)
        return view
    }
    
    
    /// Sets the symbol shape used in the chart.
    ///
    /// This modifier allows you to customize the shape of the symbols used in the chart, such as the points representing
    /// data entries.
    ///
    /// - Parameter symbol: The symbol shape to use in the chart.
    /// - Returns: A `MeasurementChartView` instance with the specified symbol shape.
    ///
    func symbolShape<C>(_ symbol: C) -> Self where C: ChartSymbolShape {
        
        var view = self
        view.symbolShape = AnyChartSymbolShape(symbol)
        return view
    }
}

