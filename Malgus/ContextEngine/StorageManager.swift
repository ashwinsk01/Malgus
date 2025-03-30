//
//  StorageManager.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation
import CryptoKit

class StorageManager {
    // Constants
    private let contextDirectoryName = "Contexts"
    private let fileExtension = "context"
    
    // Encryption key (in a real app, this would be securely stored in the keychain)
    private let encryptionKey: SymmetricKey
    
    init() {
        // For demo purposes, we're using a fixed key.
        // In a real app, this should be generated once and stored securely.
        let keyData = Data(repeating: 0, count: 32) // 256-bit key
        self.encryptionKey = SymmetricKey(data: keyData)
        
        // Create context directory if it doesn't exist
        createContextDirectory()
    }
    
    private func createContextDirectory() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let contextDirectory = documentsDirectory.appendingPathComponent(contextDirectoryName)
        
        do {
            try FileManager.default.createDirectory(at: contextDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating context directory: \(error)")
        }
    }
    
    private func getContextDirectory() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent(contextDirectoryName)
    }
    
    // Save a context to disk with encryption
    func saveContext(_ context: Context) async throws {
        guard let contextDirectory = getContextDirectory() else {
            throw StorageError.directoryNotFound
        }
        
        // Convert context to data
        let encoder = JSONEncoder()
        let contextData = try encoder.encode(context)
        
        // Encrypt the data
        let encryptedData = try encrypt(data: contextData)
        
        // Create a filename based on context ID and timestamp
        let fileName = "\(context.id.uuidString)_\(Int(context.timestamp.timeIntervalSince1970)).\(fileExtension)"
        let fileURL = contextDirectory.appendingPathComponent(fileName)
        
        // Write to disk
        try encryptedData.write(to: fileURL)
    }
    
    // Load contexts from disk with decryption
    func loadContexts(limit: Int = 20) async throws -> [Context] {
        guard let contextDirectory = getContextDirectory() else {
            throw StorageError.directoryNotFound
        }
        
        // Get all context files
        let fileManager = FileManager.default
        let fileURLs = try fileManager.contentsOfDirectory(at: contextDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            .filter { $0.pathExtension == fileExtension }
        
        // Sort by modification date (newest first)
        let sortedFiles = try fileURLs.sorted { url1, url2 in
            let date1 = try url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
            let date2 = try url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
            return date1 > date2
        }
        
        // Load only up to the limit
        let filesToLoad = sortedFiles.prefix(limit)
        
        var contexts: [Context] = []
        
        // Load and decrypt each file
        for fileURL in filesToLoad {
            do {
                let encryptedData = try Data(contentsOf: fileURL)
                let decryptedData = try decrypt(data: encryptedData)
                
                let decoder = JSONDecoder()
                let context = try decoder.decode(Context.self, from: decryptedData)
                
                contexts.append(context)
            } catch {
                print("Error loading context file \(fileURL.lastPathComponent): \(error)")
                // Continue to next file
                continue
            }
        }
        
        return contexts
    }
    
    // Delete old contexts beyond retention period
    func cleanupOldContexts(olderThan days: Int = 30) async throws {
        guard let contextDirectory = getContextDirectory() else {
            throw StorageError.directoryNotFound
        }
        
        let fileManager = FileManager.default
        let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
        
        let fileURLs = try fileManager.contentsOfDirectory(at: contextDirectory, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)
            .filter { $0.pathExtension == fileExtension }
        
        for fileURL in fileURLs {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date, modificationDate < cutoffDate {
                try fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    // MARK: - Encryption/Decryption
    
    private func encrypt(data: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.seal(data, using: encryptionKey)
        return sealedBox.combined
    }
    
    private func decrypt(data: Data) throws -> Data {
        let sealedBox = try ChaChaPoly.SealedBox(combined: data)
        return try ChaChaPoly.open(sealedBox, using: encryptionKey)
    }
    
    // MARK: - Errors
    
    enum StorageError: Error {
        case directoryNotFound
        case fileNotFound
        case encryptionError
        case decryptionError
    }
}
