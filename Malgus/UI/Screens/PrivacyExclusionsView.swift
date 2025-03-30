//
//  PrivacyExclusionsView.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct PrivacyExclusionsView: View {
    @State private var excludedApps: [AppInfo] = [
        AppInfo(name: "Safari", bundleIdentifier: "com.apple.Safari", isExcluded: true),
        AppInfo(name: "Chrome", bundleIdentifier: "com.google.Chrome", isExcluded: true),
        AppInfo(name: "Mail", bundleIdentifier: "com.apple.mail", isExcluded: true),
        AppInfo(name: "Messages", bundleIdentifier: "com.apple.Messages", isExcluded: true),
        AppInfo(name: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", isExcluded: true),
        AppInfo(name: "Terminal", bundleIdentifier: "com.apple.Terminal", isExcluded: false),
        AppInfo(name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", isExcluded: false)
    ]
    
    @State private var searchText = ""
    
    var body: some View {
        List {
            Section(header: Text("Excluded Applications").foregroundColor(Color.textSecondary)) {
                Text("Malgus won't monitor these applications for privacy reasons")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                
                TextField("Search applications", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .foregroundColor(Color.textPrimary)
            }
            .listRowBackground(Color.backgroundSecondary)
            
            Section {
                ForEach(filteredApps) { app in
                    HStack {
                        Text(app.name)
                            .foregroundColor(Color.textPrimary)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { app.isExcluded },
                            set: { newValue in
                                if let index = excludedApps.firstIndex(where: { $0.id == app.id }) {
                                    excludedApps[index].isExcluded = newValue
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                    }
                }
            }
            .listRowBackground(Color.backgroundSecondary)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Privacy Exclusions")
    }
    
    private var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return excludedApps
        } else {
            return excludedApps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    var isExcluded: Bool
}
