//
//  ContextProcessor.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import NaturalLanguage

class ContextProcessor {
    private let nlProcessor = NLProcessor()
    
    func generateContext(from activities: [Activity]) async -> Context {
        // Group activities by application
        let groupedActivities = Dictionary(grouping: activities) { $0.application }
        
        // Find the main application (most frequent)
        let mainApplication = groupedActivities.max(by: { $0.value.count < $1.value.count })?.key
        
        // Extract text content from activities
        let textContent = activities.compactMap { $0.content }.joined(separator: " ")
        
        // Extract keywords using NLP
        let keywords = await nlProcessor.extractKeywords(from: textContent)
        
        // Generate summary
        let summary = await nlProcessor.generateSummary(from: textContent, activities: activities)
        
        // Create and return the context
        return Context(
            id: UUID(),
            timestamp: Date(),
            summary: summary,
            activities: activities,
            keywords: keywords,
            mainApplication: mainApplication
        )
    }
}
