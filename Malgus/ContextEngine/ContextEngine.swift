//
//  ContextEngine.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import Combine
import NaturalLanguage

class ContextEngine: ObservableObject {
    // Published properties for UI binding
    @Published var currentContext: Context
    @Published var historicalContexts: [Context] = []
    
    // Constants
    private let contextHistoryLimit = 20
    private let activityBufferSize = 50
    private let contextUpdateThreshold = 5 // Number of activities before updating context
    
    // Private properties
    private var activityBuffer: [Activity] = []
    private var cancellables = Set<AnyCancellable>()
    private let contextProcessor = ContextProcessor()
    private let storageManager = StorageManager()
    
    // Context summary generation timer
    private var contextUpdateTimer: Timer?
    private let contextUpdateInterval: TimeInterval = 30.0 // seconds
    
    init() {
        // Initialize with an empty context
        self.currentContext = Context(
            id: UUID(),
            timestamp: Date(),
            summary: "No activity recorded yet",
            activities: [],
            keywords: [],
            mainApplication: nil
        )
        
        // Load historical contexts
        loadSavedContexts()
        
        // Subscribe to activity notifications
        NotificationCenter.default.publisher(for: .newActivityRecorded)
            .compactMap { notification -> Activity? in
                return notification.userInfo?["activity"] as? Activity
            }
            .sink { [weak self] activity in
                self?.processNewActivity(activity)
            }
            .store(in: &cancellables)
        
        // Start the context update timer
        startContextUpdateTimer()
    }
    
    private func startContextUpdateTimer() {
        contextUpdateTimer = Timer.scheduledTimer(
            withTimeInterval: contextUpdateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateContextIfNeeded()
        }
    }
    
    private func processNewActivity(_ activity: Activity) {
        // Add to buffer
        activityBuffer.append(activity)
        
        // Trim buffer if needed
        if activityBuffer.count > activityBufferSize {
            activityBuffer.removeFirst()
        }
        
        // Update context if threshold reached
        if activityBuffer.count % contextUpdateThreshold == 0 {
            updateContextIfNeeded()
        }
    }
    
    private func updateContextIfNeeded() {
        // Skip if buffer is empty
        guard !activityBuffer.isEmpty else { return }
        
        // Generate a new context
        Task {
            let newContext = await contextProcessor.generateContext(from: activityBuffer)
            
            // Update on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Only update if the new context is significantly different
                if self.isContextSignificantlyDifferent(newContext, from: self.currentContext) {
                    // Archive current context to history
                    self.historicalContexts.insert(self.currentContext, at: 0)
                    
                    // Trim history if needed
                    if self.historicalContexts.count > self.contextHistoryLimit {
                        self.historicalContexts.removeLast()
                    }
                    
                    // Update current context
                    self.currentContext = newContext
                    
                    // Save to storage
                    self.saveContext(newContext)
                }
                
                // Clear the activity buffer
                self.activityBuffer.removeAll()
            }
        }
    }
    
    private func isContextSignificantlyDifferent(_ newContext: Context, from oldContext: Context) -> Bool {
        // If main application changed, consider it significant
        if newContext.mainApplication != oldContext.mainApplication {
            return true
        }
        
        // If keywords changed significantly, consider it significant
        let commonKeywords = Set(newContext.keywords).intersection(Set(oldContext.keywords))
        let keywordSimilarity = Double(commonKeywords.count) / Double(max(newContext.keywords.count, 1))
        
        // If less than 50% keywords match, consider it significant
        return keywordSimilarity < 0.5
    }
    
    private func saveContext(_ context: Context) {
        Task {
            try? await storageManager.saveContext(context)
        }
    }
    
    private func loadSavedContexts() {
        Task {
            if let contexts = try? await storageManager.loadContexts(limit: contextHistoryLimit) {
                DispatchQueue.main.async { [weak self] in
                    self?.historicalContexts = contexts
                    
                    // Set the most recent context as current if available
                    if let mostRecent = contexts.first {
                        self?.currentContext = mostRecent
                    }
                }
            }
        }
    }
    
    // Function to provide context for Claude API
    func getContextForClaudeAPI() -> String {
        var contextString = "Current user context:\n\n"
        
        // Add main application info
        if let mainApp = currentContext.mainApplication {
            contextString += "Currently working in: \(mainApp)\n\n"
        }
        
        // Add context summary
        contextString += "Summary: \(currentContext.summary)\n\n"
        
        // Add keywords
        contextString += "Keywords: \(currentContext.keywords.joined(separator: ", "))\n\n"
        
        // Add recent activities (limited to most recent and relevant)
        contextString += "Recent activities:\n"
        let recentActivities = currentContext.activities.prefix(10)
        for activity in recentActivities {
            let appInfo = activity.application
            let timeInfo = activity.formattedTimestamp
            var contentInfo = ""
            
            if let content = activity.content, !content.isEmpty {
                contentInfo = " - \(content)"
            }
            
            contextString += "- \(timeInfo) [\(appInfo)]\(contentInfo)\n"
        }
        
        return contextString
    }
    
    deinit {
        contextUpdateTimer?.invalidate()
    }
}
