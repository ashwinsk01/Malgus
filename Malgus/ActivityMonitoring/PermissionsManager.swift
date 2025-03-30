//
//  PermissionsManager.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import AppKit

enum PermissionType {
    case accessibility
    case inputMonitoring
    case screenRecording
    case fullDiskAccess
}

class PermissionsManager {
    static let shared = PermissionsManager()
    
    // Use notification to inform observers when permission status changes
    static let permissionStatusChanged = Notification.Name("permissionStatusChanged")
    
    // Private initializer for singleton
    private init() {
        print("PermissionsManager initialized")
    }
    
    // MARK: - Permission Checking
    
    /// Checks if the specified permission has been granted
    func checkPermission(_ type: PermissionType) -> Bool {
        switch type {
        case .accessibility, .inputMonitoring:
            return checkAccessibilityPermission()
            
        case .screenRecording:
            // Screen recording permission cannot be directly checked
            // We need to attempt to capture the screen and handle failures
            return checkScreenRecordingPermission()
            
        case .fullDiskAccess:
            // Full disk access cannot be directly checked
            // Try to access a protected location
            return checkFullDiskAccessPermission()
        }
    }
    
    /// Requests the specified permission, showing UI prompts if necessary
    func requestPermission(_ type: PermissionType) {
        switch type {
        case .accessibility, .inputMonitoring:
            requestAccessibilityPermission()
            
        case .screenRecording:
            requestScreenRecordingPermission()
            
        case .fullDiskAccess:
            requestFullDiskAccessPermission()
        }
        
        // After a delay, notify observers that permission status might have changed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NotificationCenter.default.post(
                name: PermissionsManager.permissionStatusChanged,
                object: nil,
                userInfo: ["permissionType": type]
            )
        }
    }
    
    // MARK: - Accessibility & Input Monitoring
    
    private func checkAccessibilityPermission() -> Bool {
        // In modern macOS, accessibility and input monitoring use the same permission
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        print("Accessibility permission status: \(trusted ? "granted" : "denied")")
        return trusted
    }
    
    private func requestAccessibilityPermission() {
        print("Requesting accessibility permission...")
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - Screen Recording
    
    private func checkScreenRecordingPermission() -> Bool {
        // Try to capture the screen without showing the permission prompt
        // This is the best way to check if we already have permission
        var hasPermission = false
        
        DispatchQueue.global(qos: .background).sync {
            if let _ = CGWindowListCreateImage(
                .zero,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            ) {
                hasPermission = true
            }
        }
        
        print("Screen recording permission status: \(hasPermission ? "granted" : "denied")")
        return hasPermission
    }
    
    private func requestScreenRecordingPermission() {
        print("Requesting screen recording permission...")
        
        // Open the Security & Privacy preferences panel, screen recording section
        openPrivacySettingsForPermission("ScreenCapture")
        
        // Trying to capture will trigger the permission prompt
        DispatchQueue.global(qos: .background).async {
            _ = CGWindowListCreateImage(
                .zero,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            )
        }
    }
    
    // MARK: - Full Disk Access
    
    private func checkFullDiskAccessPermission() -> Bool {
        // Try to access a protected location to check for full disk access
        // Library/Application Support/AddressBook is a good test location
        let addressBookPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
            "Library/Application Support/AddressBook"
        )
        
        do {
            // Try to list contents of the directory
            _ = try FileManager.default.contentsOfDirectory(atPath: addressBookPath.path)
            print("Full disk access permission status: granted")
            return true
        } catch {
            print("Full disk access permission status: denied - \(error.localizedDescription)")
            return false
        }
    }
    
    private func requestFullDiskAccessPermission() {
        print("Requesting full disk access permission...")
        // Open the Security & Privacy preferences panel, full disk access section
        openPrivacySettingsForPermission("AllFiles")
    }
    
    // MARK: - Helpers
    
    /// Opens System Preferences > Security & Privacy > Privacy > [section]
    private func openPrivacySettingsForPermission(_ permissionType: String) {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_\(permissionType)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback to just opening Security & Privacy
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security")!)
        }
    }
    
    /// Checks all required permissions for the app
    func checkAllPermissions() -> [PermissionType: Bool] {
        return [
            .accessibility: checkPermission(.accessibility),
            .inputMonitoring: checkPermission(.inputMonitoring),
            .screenRecording: checkPermission(.screenRecording),
            .fullDiskAccess: checkPermission(.fullDiskAccess)
        ]
    }
    
    /// Requests all required permissions for the app
    func requestAllPermissions() {
        requestPermission(.accessibility)
        
        // Wait a moment before requesting the next permission to avoid UI issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.requestPermission(.screenRecording)
        }
        
        // Full disk access is requested last since it opens Preferences
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.requestPermission(.fullDiskAccess)
        }
    }
}
