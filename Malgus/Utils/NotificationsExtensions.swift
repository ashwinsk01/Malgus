//
//  NotificationsExtensions.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

// NotificationExtensions.swift
import Foundation

extension Notification.Name {
    static let newActivityRecorded = Notification.Name("newActivityRecorded")
    static let contextUpdated = Notification.Name("contextUpdated")
    static let privacySettingsChanged = Notification.Name("privacySettingsChanged")
    static let claudeResponseReceived = Notification.Name("claudeResponseReceived")
}
