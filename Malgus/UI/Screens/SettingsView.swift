import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var claudeService: ClaudeService
    @State private var apiKey = ""
    @State private var showingDeleteConfirmation = false
    @State private var isTestingAPI = false
    @State private var savedSuccessfully = false
    
    var body: some View {
        NavigationView {
            Form {
                // Claude API Section
                Section(header: Text("Claude API").foregroundColor(Color.textSecondary)) {
                    if claudeService.isConfigured {
                        // API Key is configured
                        apiKeyConfigured
                    } else {
                        // API Key not configured
                        apiKeyNotConfigured
                    }
                }
                .listRowBackground(Color.backgroundSecondary)
                
                // Privacy Section
                Section(header: Text("Privacy").foregroundColor(Color.textSecondary)) {
                    NavigationLink(destination: PrivacyExclusionsView()) {
                        Text("Configure Privacy Exclusions")
                            .foregroundColor(Color.textPrimary)
                    }
                    
                    Button("Clear All Data") {
                        // In a real app, this would have confirmation
                    }
                    .foregroundColor(Color.error)
                }
                .listRowBackground(Color.backgroundSecondary)
                
                // About Section
                Section(header: Text("About").foregroundColor(Color.textSecondary)) {
                    Text("Malgus: Next Best Move")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
                .listRowBackground(Color.backgroundSecondary)
                
                // Close Button for non-NavigationView environment
                Section {
                    Button("Close Settings") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color.brandPrimary)
                }
                .listRowBackground(Color.backgroundSecondary)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.brandPrimary)
                }
            }
            .alert("Remove API Key", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    let _ = claudeService.clearAPIKey()
                }
            } message: {
                Text("Are you sure you want to remove the Claude API key? The Next Best Move feature will not work without an API key.")
                    .foregroundColor(Color.textPrimary)
            }
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
        .frame(minWidth: 500, minHeight: 500)
    }
    
    // MARK: - Components
    
    private var apiKeyConfigured: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.success)
                Text("API Key Configured")
                    .foregroundColor(Color.textPrimary)
            }
            
            Divider()
                .background(Color.separator)
            
            HStack {
                Text("Test API Connection")
                
                Spacer()
                
                // Use the test result from claudeService
                if claudeService.isTestingAPI {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                } else {
                    Button("Test") {
                        Task {
                            let result = await claudeService.testAPIConnection()
                            print("API connection test after clicking test: \(result)")
                        }
                    }
                    .foregroundColor(Color.brandPrimary)
                }
            }
            
            if let testResult = claudeService.testResult {
                HStack {
                    Image(systemName: testResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(testResult ? Color.success : Color.error)
                    
                    Text(testResult ? "API key is valid" : "API key is invalid")
                        .foregroundColor(testResult ? Color.success : Color.error)
                }
                .padding(.top, 4)
            }
            
            Divider()
                .background(Color.separator)
            
            Button("Remove API Key") {
                showingDeleteConfirmation = true
            }
            .foregroundColor(Color.error)
        }
    }
    
    private var apiKeyNotConfigured: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Claude API Key Required")
                .font(.headline)
                .foregroundColor(Color.textPrimary)
            
            Text("Enter your API key from Anthropic's Claude API")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
            
            SecureField("Enter API Key", text: $apiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 8)
                .foregroundColor(Color.textPrimary)
            
            HStack {
                if savedSuccessfully {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.success)
                    Text("API key saved")
                        .foregroundColor(Color.success)
                        .font(.caption)
                    
                    Spacer()
                }
                
                Spacer()
                
                Button("Save API Key") {
                    guard !apiKey.isEmpty else { return }
                    
                    let success = claudeService.saveAPIKey(apiKey)
                    
                    if success {
                        savedSuccessfully = true
                        
                        // Auto-clear the success message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            savedSuccessfully = false
                        }
                        
                        // Test the API connection
                        Task {
                            let testResult = await claudeService.testAPIConnection()
                            print("API connection test after saving key: \(testResult)")
                        }
                    }
                    
                    apiKey = ""
                }
                .disabled(apiKey.isEmpty)
                .foregroundColor(apiKey.isEmpty ? Color.textSecondary : Color.brandPrimary)
            }
            
            Text("Your API key should start with 'sk-ant-' and should not contain any extra spaces")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ClaudeService())
    }
}
