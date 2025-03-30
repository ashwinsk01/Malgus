//
//  NextBestMoveView.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct NextBestMoveView: View {
    @EnvironmentObject var contextEngine: ContextEngine
    @EnvironmentObject var claudeService: ClaudeService
    
    @State private var query = ""
    @State private var recommendation: String?
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Context Section
                contextSection
                
                // API Key Not Configured Warning
                if !claudeService.isConfigured {
                    apiKeyWarningSection
                }
                
                // Query Section
                querySection
                
                // Results Section
                resultSection
            }
            .padding()
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Next Best Move")
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(claudeService)
        }
    }
    
    // MARK: - Section Components
    
    private var contextSection: some View {
        VStack(alignment: .leading) {
            Text("Current Context")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            if contextEngine.currentContext.activities.isEmpty {
                emptyContextView
            } else {
                ContextView(context: contextEngine.currentContext)
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(8)
            }
        }
    }
    
    private var emptyContextView: some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(Color.warning)
            
            Text("No activity data recorded yet")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
            
            Text("Enable activity monitoring in the sidebar to start building context")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private var apiKeyWarningSection: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Image(systemName: "key.slash.fill")
                    .font(.title2)
                    .foregroundColor(Color.warning)
                
                Text("Claude API Key Not Configured")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
            }
            
            Text("The Next Best Move feature requires a Claude API key to generate recommendations.")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Configure API Key") {
                showingSettings = true
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.brandPrimary)
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.top, 5)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private var querySection: some View {
        VStack(alignment: .leading) {
            Text("Ask for a Next Best Move")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            TextField("What should I do next?", text: $query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)
                .disabled(isLoading || !claudeService.isConfigured)
            
            Button(action: getNextBestMove) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(Color.warning)
                    }
                    Text("Get Recommendation")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    !query.isEmpty && claudeService.isConfigured && !isLoading
                        ? Color.brandPrimary
                        : Color.gray.opacity(0.5)
                )
                .cornerRadius(8)
            }
            .disabled(query.isEmpty || isLoading || !claudeService.isConfigured)
        }
    }
    
    private var resultSection: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(errorMessage)
            } else if let recommendation = recommendation {
                recommendationView(recommendation)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 15) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Generating recommendation...")
                .font(.subheadline)
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.error)
                
                Text("Error")
                    .font(.headline)
                    .foregroundColor(Color.error)
                
                Spacer()
                
                Button(action: {
                    errorMessage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            if message.contains("Invalid bearer token") || message.contains("401") {
                Button("Update API Key") {
                    showingSettings = true
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 6)
                .background(Color.brandPrimary)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private func recommendationView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color.warning)
                
                Text("Next Best Move")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text(formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Text(text)
                .font(.body)
                .foregroundColor(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Spacer()
                
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(text, forType: .string)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(Color.brandPrimary)
                }
                
                Button(action: {
                    // In a real app, this would implement the recommendation
                }) {
                    Label("Apply", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(Color.success)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private func getNextBestMove() {
        guard !query.isEmpty, claudeService.isConfigured else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await claudeService.getNextBestMove(
                    query: query,
                    context: contextEngine.currentContext
                )
                
                DispatchQueue.main.async {
                    self.recommendation = result
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
