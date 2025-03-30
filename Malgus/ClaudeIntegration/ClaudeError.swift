//
//  ClaudeError.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import Foundation

// Error types for Claude API
enum ClaudeError: Error, LocalizedError {
    case notConfigured
    case invalidResponse
    case invalidResponseFormat
    case requestFormatError
    case apiError(statusCode: Int, message: String)
    case networkError(message: String)
    case invalidApiKey
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Claude API is not configured. Please add your API key in settings."
        case .invalidResponse:
            return "Invalid response received from Claude API."
        case .invalidResponseFormat:
            return "Claude API response format was unexpected."
        case .requestFormatError:
            return "Error creating request to Claude API."
        case .apiError(let statusCode, let message):
            return "Claude API error (code \(statusCode)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidApiKey:
            return "Invalid API key. Please check your Claude API key in Settings."
        }
    }
}
