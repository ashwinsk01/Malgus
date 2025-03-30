//
//  DashboardView.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var activityMonitor: ActivityMonitor
    @EnvironmentObject var contextEngine: ContextEngine
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Status Card
                statusCard
                
                // Current Context
                VStack(alignment: .leading) {
                    Text("Current Context")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    ContextView(context: contextEngine.currentContext)
                        .padding()
                        .background(Color.backgroundSecondary)
                        .cornerRadius(8)
                }
                
                // Recent Activities
                VStack(alignment: .leading) {
                    Text("Recent Activities")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    ForEach(activityMonitor.recentActivities.prefix(5)) { activity in
                        ActivityRow(activity: activity)
                            .padding(.vertical, 4)
                    }
                }
                
                // Privacy Settings
                VStack(alignment: .leading) {
                    Text("Privacy Controls")
                        .font(.headline)
                        .foregroundColor(Color.textPrimary)
                    
                    privacyControls
                }
            }
            .padding()
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Dashboard")
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.success)
                Text("Malgus Active")
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Pause")
                        .font(.subheadline)
                        .foregroundColor(Color.brandPrimary)
                }
            }
            
            Divider()
                .background(Color.separator)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Activities Recorded")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    Text("\(activityMonitor.recentActivities.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Contexts Generated")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    Text("\(contextEngine.historicalContexts.count + 1)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Storage Used")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    Text("32 MB")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.textPrimary)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private var privacyControls: some View {
        VStack {
            Toggle("Enable Keystroke Monitoring", isOn: $activityMonitor.keyLoggingEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
            
            Toggle("Enable Screen Analysis", isOn: $activityMonitor.screenAnalysisEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
            
            Toggle("Enable App Tracking", isOn: $activityMonitor.appTrackingEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
            
            Button(action: {}) {
                Text("Configure Privacy Exclusions")
                    .font(.subheadline)
                    .foregroundColor(Color.brandPrimary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
}
