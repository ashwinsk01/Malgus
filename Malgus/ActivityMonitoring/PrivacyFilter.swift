//
//  PrivacyFilter.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation

class PrivacyFilter {
    // List of applications to exclude from monitoring
    private var excludedApps = [
        "com.apple.Safari",
        "com.google.Chrome",
        "com.apple.mail",
        "com.apple.iChat",
        "com.apple.Messages",
        "com.tinyspeck.slackmacgap",
        "com.apple.keychainaccess"
    ]
    
    // List of sensitive terms to redact
    private var sensitiveTerms = [
        "password",
        "credit",
        "ssn",
        "social security",
        "account",
        "secret",
        "private",
        "confidential"
    ]
    
    // User customizable exclusions
    private(set) var userExcludedApps = [String]()
    
    // MARK: - Public Methods
    
    func isAppExcluded(_ bundleIdentifier: String) -> Bool {
        return excludedApps.contains(bundleIdentifier) || userExcludedApps.contains(bundleIdentifier)
    }
    
    func excludeApp(_ bundleIdentifier: String) {
        if !userExcludedApps.contains(bundleIdentifier) {
            userExcludedApps.append(bundleIdentifier)
            saveUserExclusions()
        }
    }
    
    func includeApp(_ bundleIdentifier: String) {
        if let index = userExcludedApps.firstIndex(of: bundleIdentifier) {
            userExcludedApps.remove(at: index)
            saveUserExclusions()
        }
    }
    
    func filterSensitiveContent(_ content: String) -> String {
        var filteredContent = content
        
        // Check if content contains any sensitive terms
        for term in sensitiveTerms {
            if filteredContent.lowercased().contains(term) {
                // Redact content that contains sensitive terms
                let regex = try? NSRegularExpression(pattern: "(?i)\\b.{0,20}\\b\(term)\\b.{0,20}\\b")
                if let matches = regex?.matches(in: filteredContent, range: NSRange(filteredContent.startIndex..., in: filteredContent)) {
                    for match in matches.reversed() {
                        if let range = Range(match.range, in: filteredContent) {
                            filteredContent = filteredContent.replacingCharacters(in: range, with: "[REDACTED]")
                        }
                    }
                }
            }
        }
        
        return filteredContent
    }
    
    // MARK: - Private Methods
    
    private func saveUserExclusions() {
        UserDefaults.standard.set(userExcludedApps, forKey: "userExcludedApps")
    }
    
    private func loadUserExclusions() {
        if let savedExclusions = UserDefaults.standard.stringArray(forKey: "userExcludedApps") {
            userExcludedApps = savedExclusions
        }
    }
    
    init() {
        loadUserExclusions()
    }
}
