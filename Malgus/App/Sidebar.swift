//
//  Sidebar.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

// Sidebar.swift
import SwiftUI

struct Sidebar: View {
    @EnvironmentObject var activityMonitor: ActivityMonitor
    
    var body: some View {
        List {
            NavigationLink(destination: DashboardView()) {
                Label("Dashboard", systemImage: "speedometer")
                    .foregroundColor(Color.textPrimary)
            }
            
            NavigationLink(destination: ActivityTimelineView()) {
                Label("Activity Timeline", systemImage: "clock")
                    .foregroundColor(Color.textPrimary)
            }
            
            NavigationLink(destination: NextBestMoveView()) {
                Label("Next Best Move", systemImage: "arrow.right.circle")
                    .foregroundColor(Color.textPrimary)
            }
            
            Divider()
                .background(Color.separator)
            
            Section(header: Text("Monitoring").foregroundColor(Color.textSecondary)) {
                Toggle("Enable Keystroke Monitoring", isOn: $activityMonitor.keyLoggingEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                    .foregroundColor(Color.textPrimary)
                
                Toggle("Enable Screen Analysis", isOn: $activityMonitor.screenAnalysisEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                    .foregroundColor(Color.textPrimary)
                
                Toggle("Enable App Tracking", isOn: $activityMonitor.appTrackingEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                    .foregroundColor(Color.textPrimary)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 220)
        .background(Color.backgroundPrimary)
    }
}
