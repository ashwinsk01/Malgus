import SwiftUI

@main
struct MalgusApp: App {
    @StateObject private var activityMonitor = ActivityMonitor()
    @StateObject private var contextEngine = ContextEngine()
    @StateObject private var claudeService = ClaudeService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(activityMonitor)
                .environmentObject(contextEngine)
                .environmentObject(claudeService)
        }
        .commands {
            // Menu commands
            CommandGroup(after: .appInfo) {
                Button("Privacy Settings") {
                    NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }
        }
    }
}
