//
//  Context.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation

struct Context: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let summary: String
    let activities: [Activity]
    let keywords: [String]
    let mainApplication: String?
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}
