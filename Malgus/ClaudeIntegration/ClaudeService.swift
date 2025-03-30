import Foundation

class ClaudeService: ObservableObject {
    // API configuration
    private var apiKey: String?
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    
    // Use the exact model from the documentation
    private let model = "claude-3-7-sonnet-20250219" // Fall back to an older model if the newest isn't available
    
    // Published properties
    @Published var isConfigured: Bool = false
    @Published var isTestingAPI: Bool = false
    @Published var testResult: Bool? = nil
    
    // Initialization
    init() {
        // Try to load API key from secure storage
        self.apiKey = KeychainManager.shared.getAPIKey()
        self.isConfigured = self.apiKey != nil && !(self.apiKey?.isEmpty ?? true)
        
        print("ClaudeService initialized, API key configured: \(isConfigured)")
    }
    
    // Save API key
    func saveAPIKey(_ key: String) -> Bool {
        // Trim whitespace that might have been copied
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let saveResult = KeychainManager.shared.saveAPIKey(trimmedKey)
        
        if saveResult {
            self.apiKey = trimmedKey
            self.isConfigured = !trimmedKey.isEmpty
            print("API key saved successfully")
        }
        
        return saveResult
    }
    
    // Clear API key
    func clearAPIKey() -> Bool {
        let deleteResult = KeychainManager.shared.deleteAPIKey()
        
        if deleteResult {
            self.apiKey = nil
            self.isConfigured = false
            print("API key cleared")
        }
        
        return deleteResult
    }
    
    // Test API connection based on the official documentation
    func testAPIConnection() async -> Bool {
        // Reset test result
        DispatchQueue.main.async {
            self.isTestingAPI = true
            self.testResult = nil
        }
        
        // Ensure we have an API key
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            DispatchQueue.main.async {
                self.testResult = false
                self.isTestingAPI = false
            }
            return false
        }
        
        // Create a simple request to check if the API key is valid
        // USING THE EXACT HEADERS FROM THE DOCUMENTATION
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")  // This is the key change!
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Create a minimal request body to test the API
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 10,
            "messages": [
                ["role": "user", "content": "Hello, world"]
            ]
        ]
        
        // Convert request body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error creating test request: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.testResult = false
                self.isTestingAPI = false
            }
            return false
        }
        
        // Print the exact request we're sending
        print("Testing API with:")
        print("URL: \(baseURL)")
        print("Headers: x-api-key, anthropic-version: 2023-06-01, content-type: application/json")
        print("Model: \(model)")
        
        do {
            // Send the test request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Get HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.testResult = false
                    self.isTestingAPI = false
                }
                return false
            }
            
            // Check if the request was successful (200 OK)
            let success = httpResponse.statusCode == 200
            
            // Log response for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("API test response (\(httpResponse.statusCode)): \(responseString.prefix(100))")
            
            // Update UI
            DispatchQueue.main.async {
                self.testResult = success
                self.isTestingAPI = false
            }
            
            print("API connection test result: \(success)")
            return success
        } catch {
            print("API test error: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.testResult = false
                self.isTestingAPI = false
            }
            
            return false
        }
    }
    
    // Get next best move recommendation using correct API format
    func getNextBestMove(query: String, context: Context) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw ClaudeError.notConfigured
        }
        
        print("Getting next best move for query: \(query)")
        print("Using model: \(model)")
        
        // Construct the prompt with context
        let prompt = constructPrompt(query: query, context: context)
        
        // Create the request USING THE EXACT HEADERS FROM THE DOCUMENTATION
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")  // THIS IS THE KEY CHANGE!
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Create the request body as specified in Claude API docs
        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        // Debug print what we're sending
        print("Request URL: \(baseURL)")
        print("Headers: x-api-key, anthropic-version: 2023-06-01, content-type: application/json")
        
        // Serialize to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("JSON serialization error: \(error.localizedDescription)")
            throw ClaudeError.requestFormatError
        }
        
        do {
            // Send the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ClaudeError.invalidResponse
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            // Get the response as string for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            
            if httpResponse.statusCode != 200 {
                // Log the full error response
                print("API Error Response: \(responseString)")
                
                if responseString.contains("authentication_error") {
                    throw ClaudeError.invalidApiKey
                }
                
                throw ClaudeError.apiError(statusCode: httpResponse.statusCode, message: responseString)
            }
            
            // Print part of response for debugging
            print("API Response (preview): \(responseString.prefix(100))")
            
            // Parse the response
            do {
                if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Extract content from the response
                    if let content = responseDict["content"] as? [[String: Any]],
                       let firstContent = content.first,
                       let text = firstContent["text"] as? String {
                        return text
                    }
                    
                    // Log what we found for debugging
                    print("Response keys: \(responseDict.keys.joined(separator: ", "))")
                    
                    // Return a generic message
                    return "Couldn't find content in the response. Please try again."
                }
                
                throw ClaudeError.invalidResponseFormat
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                return "Error parsing response: \(error.localizedDescription)"
            }
        } catch {
            // Handle network errors
            print("Network or API error: \(error.localizedDescription)")
            
            if let claudeError = error as? ClaudeError {
                throw claudeError
            } else {
                throw ClaudeError.networkError(message: error.localizedDescription)
            }
        }
    }
    
    // Construct the prompt for Claude
    private func constructPrompt(query: String, context: Context) -> String {
        var prompt = """
        # User Context
        
        """
        
        // Add main application info
        if let mainApp = context.mainApplication {
            prompt += "Currently working in: \(mainApp)\n\n"
        }
        
        // Add context summary
        prompt += "Context Summary: \(context.summary)\n\n"
        
        // Add keywords
        if !context.keywords.isEmpty {
            prompt += "Keywords: \(context.keywords.joined(separator: ", "))\n\n"
        }
        
        // Add recent activities (limited to most recent and relevant)
        if !context.activities.isEmpty {
            prompt += "Recent Activities:\n"
            let recentActivities = context.activities.prefix(5)
            for activity in recentActivities {
                let appInfo = activity.application
                let timeInfo = activity.formattedTimestamp
                var contentInfo = ""
                
                if let content = activity.content, !content.isEmpty {
                    // Limit content length to avoid token bloat
                    let limitedContent = content.count > 100 ? String(content.prefix(100)) + "..." : content
                    contentInfo = " - \(limitedContent)"
                }
                
                prompt += "- \(timeInfo) [\(appInfo)]\(contentInfo)\n"
            }
            prompt += "\n"
        }
        
        // Add user query
        prompt += "# User Question\n\(query)\n\n"
        
        // Add instructions for Claude
        prompt += """
        # Instructions
        - Based on the user's current context and question, provide a helpful "next best move" recommendation.
        - Be concise and specific.
        - Focus on actionable advice that helps the user make progress.
        - If the context isn't clear, provide general guidance based on the keywords and activities.
        - Format your response to be easily scannable.
        - Keep your response under 300 words.
        """
        
        return prompt
    }
}
