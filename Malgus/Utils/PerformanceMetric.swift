//
//  PerformanceMetric.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation

class PerformanceMetric {
    let name: String
    private(set) var count: Int = 0
    private(set) var totalTime: Double = 0
    private(set) var minTime: Double = Double.infinity
    private(set) var maxTime: Double = 0
    
    init(name: String) {
        self.name = name
    }
    
    func addMeasurement(_ time: Double) {
        count += 1
        totalTime += time
        minTime = min(minTime, time)
        maxTime = max(maxTime, time)
    }
    
    var averageTime: Double {
        return count > 0 ? totalTime / Double(count) : 0
    }
}
