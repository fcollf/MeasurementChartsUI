//
//  Comparable+Clamped.swift
//  MeasurementChartsUI
//
//  Created by fcollf on 3/3/24.
//


import Foundation


extension Comparable {
    
    /// Clamps this value to the specified closed range.
    ///
    /// If this value is less than the lower bound of the range, the lower bound is returned.
    /// If this value is greater than the upper bound of the range, the upper bound is returned. Otherwise, this value itself is returned.
    ///
    /// - Parameter range: The closed range within which to clamp this value.
    /// - Returns: The clamped value.
    ///
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
