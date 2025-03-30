//
//  ActivityTimelineView.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct ActivityTimelineView: View {
    @EnvironmentObject var activityMonitor: ActivityMonitor
    @State private var selectedActivityType: ActivityType?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Filter by Type:")
                    .font(.subheadline)
                    .foregroundColor(Color.textPrimary)
                
                Picker("Activity Type", selection: $selectedActivityType) {
                    Text("All").tag(nil as ActivityType?)
                    Text("Keystrokes").tag(ActivityType.keystroke as ActivityType?)
                    Text("Screen Content").tag(ActivityType.screenContent as ActivityType?)
                    Text("App Switches").tag(ActivityType.applicationSwitch as ActivityType?)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            List {
                ForEach(filteredActivities) { activity in
                    ActivityRow(activity: activity)
                        .listRowBackground(Color.backgroundSecondary)
                }
            }
            .background(Color.backgroundPrimary)
        }
        .navigationTitle("Activity Timeline")
    }
    
    private var filteredActivities: [Activity] {
        if let type = selectedActivityType {
            return activityMonitor.recentActivities.filter { $0.type == type }
        } else {
            return activityMonitor.recentActivities
        }
    }
}
