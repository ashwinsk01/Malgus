//
//  KeychainManager.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import Security

// Improved KeychainManager with better error handling
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.malgus.nextbestmove"
    private let account = "claudeapi"
    
    private init() {}
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        // First delete any existing key
        // Ignore the result since we don't care if the delete succeeded
        _ = deleteAPIKey()
        
        // Then save the new key
        let keyData = apiKey.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            // If the item already exists, try to update it instead
            if status == errSecDuplicateItem {
                let updateQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                    kSecAttrAccount as String: account
                ]
                
                let updateAttributes: [String: Any] = [
                    kSecValueData as String: keyData
                ]
                
                let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
                
                if updateStatus != errSecSuccess {
                    print("Error updating API key in Keychain: \(updateStatus)")
                    return false
                }
                return true
            } else {
                print("Error saving API key to Keychain: \(status)")
                return false
            }
        }
        
        return true
    }
    
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            if status != errSecItemNotFound {
                print("Error retrieving API key from Keychain: \(status)")
            }
            return nil
        }
    }
    
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Success or "item not found" are both considered successful deletion
        if status == errSecSuccess || status == errSecItemNotFound {
            return true
        } else {
            print("Error deleting API key from Keychain: \(status)")
            return false
        }
    }
    
    // Helper method to check if there's a valid API key stored
    func hasValidAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}
