//
//  Dimension+BaseUnit.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 10/3/24.
//


import Foundation


extension Dimension {
    
    /// An instance property to access the static `baseUnit` method dynamically based on the subclass type
    var baseUnit: Self {
        Self.baseUnit()
    }
}
