//
//  ContentView.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var activityMonitor: ActivityMonitor
    @EnvironmentObject var contextEngine: ContextEngine
    @EnvironmentObject var claudeService: ClaudeService
    
    @State private var showingSettings = false
    @State private var showingDebugger = false
    @State private var selectedTab: Tab? = .dashboard
    
    enum Tab: String, Identifiable {
        case dashboard = "Dashboard"
        case timeline = "Activity Timeline"
        case nextBestMove = "Next Best Move"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .dashboard: return "speedometer"
            case .timeline: return "clock"
            case .nextBestMove: return "arrow.right.circle"
            }
        }
        
        var view: some View {
            switch self {
            case .dashboard:
                return AnyView(DashboardView())
            case .timeline:
                return AnyView(ActivityTimelineView())
            case .nextBestMove:
                return AnyView(NextBestMoveView())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            List {
                ForEach([Tab.dashboard, Tab.timeline, Tab.nextBestMove], id: \.self) { tab in
                    NavigationLink(
                        destination: tab.view,
                        tag: tab,
                        selection: $selectedTab
                    ) {
                        Label(tab.rawValue, systemImage: tab.iconName)
                            .foregroundColor(Color.textPrimary)
                    }
                }
                
                Divider()
                    .background(Color.separator)
                
                Section(header: Text("Monitoring").foregroundColor(Color.textSecondary)) {
                    Toggle("Keystroke Monitoring", isOn: $activityMonitor.keyLoggingEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                        .foregroundColor(Color.textPrimary)
                    
                    Toggle("Screen Analysis", isOn: $activityMonitor.screenAnalysisEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                        .foregroundColor(Color.textPrimary)
                    
                    Toggle("App Tracking", isOn: $activityMonitor.appTrackingEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color.brandPrimary))
                        .foregroundColor(Color.textPrimary)
                }
                
                // Debug section in development
                #if DEBUG
                Button(action: {
                    showingDebugger = true
                }) {
                    Label("Debug Tools", systemImage: "ladybug.fill")
                        .foregroundColor(Color.error)
                }
                #endif
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 220)
            .background(Color.backgroundPrimary)
            
            // Initial content
            Tab.dashboard.view
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .frame(minWidth: 900, minHeight: 600)
        .background(Color.backgroundPrimary)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                        .foregroundColor(Color.brandPrimary)
                }
            }
            
            #if DEBUG
            ToolbarItem(placement: .automatic) {
                debugButton
            }
            #endif
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingDebugger) {
            PermissionDebugView()
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    var debugButton: some View {
        Button(action: {
            showingDebugger = true
        }) {
            Label("Debug", systemImage: "ladybug.fill")
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.error.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

// Placeholder for PermissionDebugView if not defined elsewhere
#if DEBUG
struct PermissionDebugView: View {
    var body: some View {
        Text("Permission Debugger")
            .frame(width: 500, height: 400)
    }
}
#endif
