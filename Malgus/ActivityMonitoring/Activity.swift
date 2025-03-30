//
//  Activity.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

// Activity.swift
import Foundation

enum ActivityType: String, Codable {
    case keystroke
    case screenContent
    case applicationSwitch
    case mouseMovement
    case browserNavigation
}

struct Activity: Identifiable, Codable {
    let id = UUID()
    let type: ActivityType
    let timestamp: Date
    let application: String
    let bundleIdentifier: String?
    let content: String?
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}
