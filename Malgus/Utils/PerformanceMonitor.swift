//
//  PerformanceMonitor.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import os.log

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.malgus.nextbestmove", category: "Performance")
    private var metrics: [String: PerformanceMetric] = [:]
    
    private init() {}
    
    // Track execution time of a block
    func measure<T>(_ name: String, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        recordMetric(name: name, value: timeElapsed)
        
        return result
    }
    
    // Async version for measuring async functions
    func measureAsync<T>(_ name: String, _ block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        recordMetric(name: name, value: timeElapsed)
        
        return result
    }
    
    // Record a performance metric
    private func recordMetric(name: String, value: Double) {
        if let existingMetric = metrics[name] {
            existingMetric.addMeasurement(value)
        } else {
            let metric = PerformanceMetric(name: name)
            metric.addMeasurement(value)
            metrics[name] = metric
        }
        
        // Log long operations
        if value > 0.1 { // 100ms
            logger.debug("Performance: \(name) took \(value, privacy: .public) seconds")
        }
    }
    
    // Get performance report
    func getPerformanceReport() -> [PerformanceMetric] {
        return Array(metrics.values)
    }
    
    // Reset metrics
    func resetMetrics() {
        metrics.removeAll()
    }
}
