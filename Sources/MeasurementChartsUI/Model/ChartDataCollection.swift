//
//  ChartDataCollection.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 13/3/24.
//


import Foundation


/// `ChartDataCollection` manages a collection of chart data entries sorted by date in ascending order.
///
/// This class conforms to `RandomAccessCollection` to provide fast access to its elements and supports equatable comparisons.
///  It's designed to store any chart data entries that conform to the `ChartDataEntry` protocol.
///
/// Usage of this class allows for direct manipulation of chart data entries through subscripting and supports standard collection operations such as iteration and indexing.
///
final class ChartDataCollection<D: ChartDataEntry>: RandomAccessCollection, Equatable {
   

    // MARK: - Private Properties
    
    
    /// Stores the chart data entries.
    private var data: [D] = []
    
    
    // MARK: - Public Properties
    
    
    /// The position of the first element in a nonempty collection.
    var startIndex: Int {
        data.startIndex
    }
    
    /// The position of the last element in a nonempty collection.
    var endIndex: Int {
        data.endIndex
    }
    
    /// A Boolean value indicating whether the collection is empty
    var isEmpty: Bool {
        data.isEmpty
    }
    
    /// Represents the range of dates covered by the chart data entries.
    var dateRange: ClosedRange<Date> = .now ... .now
    
    /// Represents the range of values (e.g., measurement values) present in the chart data entries
    var valueRange: ClosedRange<Double> = 0.0 ... 0.0
    
    
    // MARK: - Initializer
    
    
    /// Initializes an empty collection.
    ///
    init() {
        
        let now = Date.now
        
        self.data = []
        self.dateRange = now ... now
        self.valueRange = 0.0 ... 0.0
    }
    
    
    /// Initializes a new collection with the contents of the specified sequence.
    ///
    /// - Parameter sequence: The sequence of chart data entries to store in the collection.
    ///
    init<S: Sequence>(contentsOf sequence: S) where S.Element == D {
        
        let now = Date.now
        
        self.data = sequence.sorted { $0.date <= $1.date  }
        
        // Date range
        if let first = data.first?.date, let last = data.last?.date {
            self.dateRange = first ... last
        } else {
            self.dateRange = now ... now
        }
        
        // Value range
        if let min = data.min, let max = data.max {
            self.valueRange = min.value ... max.value
        } else {
            self.valueRange = 0.0 ... 0.0
        }
    }
    
    
    // MARK: - Public Methods
    
    
    /// Accesses the chart data entry at the specified position.
    ///
    /// This subscript provides both read and write access to the chart data entries. 
    /// The index must be within the bounds of the collection, otherwise accessing this subscript will trigger a runtime error.
    ///
    /// - Parameter index: The position of the chart data entry to access. `index` must be greater than or equal to `startIndex` and less than `endIndex`.
    /// - Returns: The chart data entry at the specified index.
    ///
    subscript(_ index: Int) -> D {
        
        get { data[index] }
//        set { data[index] = newValue }
    }
    
    
    // MARK: - Equatable
    
    
    /// Returns a Boolean value indicating whether two collections are equal.
    ///
    /// - Parameters:
    ///   - lhs: Left collection to compare.
    ///   - rhs: Right collection to compare.
    ///
    static func ==(lhs: ChartDataCollection<D>, rhs: ChartDataCollection<D>) -> Bool {
        lhs.data == rhs.data
    }
}
