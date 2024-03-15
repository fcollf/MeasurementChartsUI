//
//  MeasurementChartEntry.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 28/2/24.
//


import Foundation


// MARK: - Chart Data Entry


/// Protocol defining a standardized structure for an individual data entry in a chart.
///
/// This protocol ensures that each chart data entry has a uniform representation,
/// including a measurement and it's corresponding date.
///
public protocol ChartDataEntry: Identifiable, Hashable, Equatable {
    
    /// The type of unit associated with the measurement.
    associatedtype U: Dimension
    
    /// The date associated with this measurement
    var date: Date { get }
    
    /// The measured value in the specified unit
    var measurement: Measurement<U> { get }
}


public extension ChartDataEntry {
    
    /// The double value  for this entry
    var value: Double {
        measurement.value
    }
    
    /// The unit for this entry
    var unit: Dimension {
        measurement.unit
    }
}


// MARK: - Grouped Chart Entry


/// Represents a grouped set of measurements for a specific date.
///
/// This class collects multiple measurements under a single date entry, allowing for
/// aggregate operations.
///
final class GroupedChartDataEntry<U: Dimension>: ChartDataEntry {
    
    
    // MARK: - Private Properties
    
    
    /// A set of measurements for this entry
    private var measurements: Set<Measurement<U>>
    
    
    // MARK: - Public Properties
    
    
    /// Unique ID for the entry
    private (set) var id: UUID
    
    /// The date associated with this group of measurements
    private (set) var date: Date
    
    /// The unit of measurement for this entry
    private (set) var unit: U
    
    /// The average measurement value of the group
    var measurement: Measurement<U> {
        average
    }
    
    /// Measurement for zero value
    var zero: Measurement<U> {
        
        Measurement(value: 0, unit: unit)
    }
    
    /// The total number of measurements within the group.
    var count: Int {

        measurements.count
    }
    
    /// The sum of all measurement values within the group.
    var sum: Measurement<U> {
        
        measurements.reduce(zero) { $0 + $1 }
    }
    
    /// The average value of all measurements within the group.
    var average: Measurement<U> {
        
        count > 0 ? sum / Double(count) : zero
    }
    
    
    // MARK: - Public Methods
    
    
    /// Initializes a new entry with an empty set of  measurements for the given date.
    ///
    /// - Parameters:
    ///   - date: The date of the measurement.
    ///   - unit: The base unit for this set of measurements.
    ///
    init(_ date: Date, unit: U) {
        
        self.id = UUID()
        self.date = date
        self.unit = unit
        self.measurements = .init()
    }
    
    
    /// Initializes a new entry with a single measurement for the given date.
    ///
    /// - Parameters:
    ///   - date: The date of the measurement.
    ///   - measurement: A single measurement taken on the given date.
    ///
    init( _ date: Date, measurement: Measurement<U>) {
        
        self.id = UUID()
        self.date = date
        self.unit = measurement.unit
        self.measurements = .init([measurement])
    }
    
    
    /// Adds a single measurement to this entry.
    ///
    /// - Parameter measurement: The measurement to add.
    ///
    func insert(_ measurement: Measurement<U>) {
        self.measurements.insert(measurement)
    }
    
    
    /// Adds multiple measurements to this entry.
    /// - Parameter measurements: The measurements to append.
    ///
    func insert<S: Sequence>(_ measurements: S) where S.Element == Measurement<U> {
        self.measurements.formUnion(measurements)
    }
}


// MARK: - Hashable


extension GroupedChartDataEntry {
    
    /// Hashes the essential components of this entry by feeding them into the given hasher.
    /// - Parameter hasher: The hasher to use for combining the components of this instance.
    ///
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: - Equatable


extension GroupedChartDataEntry {
    
    /// Compares two instances of `MeasurementChartGroupedEntry` for equality.
    /// Entries are considered equal if their `id` properties are the same.
    ///
    /// - Parameters:
    ///   - lhs: An instance of `MeasurementChartGroupedEntry`.
    ///   - rhs: Another instance of `MeasurementChartGroupedEntry`.
    /// - Returns: A Boolean value indicating whether the two instances are equal.
    ///
    static func == (lhs: GroupedChartDataEntry, rhs: GroupedChartDataEntry) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Chart Data Entry Collections


extension RandomAccessCollection where Element: ChartDataEntry {


    // MARK: - Public Properties

    
    /// A measurement with a zero value, uses by default the unit of the first element in the collection.
    private var zero: Measurement<Element.U>? {
        
        if let unit = first?.measurement.unit {
            Measurement(value: 0.0, unit: unit)
        } else {
            nil
        }
    }

    /// The minimum average value among all entries in the array.
    var min: Measurement<Element.U>? {
        compactMap { $0.measurement }.min()
    }

    /// The maximum average value among all entries in the array.
    var max: Measurement<Element.U>? {
        compactMap { $0.measurement }.max()
    }

    /// The total sum of all average values in the array.
    var sum: Measurement<Element.U>? {
        
        if !isEmpty, let zero = zero {
            
            reduce(zero) { $0 + $1.measurement }
            
        } else {
            
            nil
        }
    }

    /// The average value of all average values in the array.
    var average: Measurement<Element.U>? {
        
        if let sum = sum {
            sum / Double(count)
        } else {
            nil
        }
    }


    // MARK: - Public Methods


    /// Calculates the average value of entries within the specified date range.
    ///
    /// This method filters the entries based on the specified start (`from`) and end (`to`) dates,
    /// and then calculates the average value of these filtered entries. If no entries fall within
    /// the specified range or the filtered entries have no measurements, the result is `zero`.
    ///
    /// - Parameters:
    ///   - from: The start date of the range.
    ///   - to: The end date of the range.
    /// - Returns: The average value of entries within the specified date range, or `zero` if there are no entries or measurements within this range.
    /// 
    func average(from: Date, to: Date) -> Measurement<Element.U>? {
        filter { $0.date >= from && $0.date <= to }.average
    }
}

