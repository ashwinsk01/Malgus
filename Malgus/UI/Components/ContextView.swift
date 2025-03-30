import SwiftUI

struct ContextView: View {
    let context: Context
    @State private var showAllActivities = false
    
    // Constants
    private let maxVisibleActivities = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Section
            headerSection
            
            // Summary Section
            summarySection
            
            // Keywords Section
            if !context.keywords.isEmpty {
                keywordsSection
            }
            
            // Activities Section
            if !context.activities.isEmpty {
                activitiesSection
            } else {
                noActivitiesSection
            }
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(Color.textSecondary)
            
            Text(context.formattedTimestamp)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
            
            Spacer()
            
            if let app = context.mainApplication {
                Label(app, systemImage: "app.badge")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if context.summary == "No activity recorded yet" {
                Text("No context available")
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                    .italic()
            } else {
                Text(context.summary)
                    .font(.body)
                    .foregroundColor(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true) // Allows text to grow vertically
            }
        }
    }
    
    private var keywordsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(context.keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.grid.opacity(0.3))
                        .cornerRadius(4)
                }
            }
        }
    }
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .background(Color.separator)
            
            Text("Recent Activities")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
            
            // Show limited activities unless "show all" is toggled
            ForEach(visibleActivities) { activity in
                ActivityRow(activity: activity)
            }
            
            // Show "view more" button if there are more activities
            if context.activities.count > maxVisibleActivities && !showAllActivities {
                Button(action: { showAllActivities = true }) {
                    Text("Show \(context.activities.count - maxVisibleActivities) more activities")
                        .font(.caption)
                        .foregroundColor(Color.brandPrimary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            } else if showAllActivities {
                Button(action: { showAllActivities = false }) {
                    Text("Show less")
                        .font(.caption)
                        .foregroundColor(Color.brandPrimary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
        }
    }
    
    private var noActivitiesSection: some View {
        VStack(alignment: .center, spacing: 4) {
            Divider()
                .background(Color.separator)
            
            Text("No recent activities")
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                .italic()
                .padding(.top, 4)
        }
    }
    
    // MARK: - Helper Properties
    
    private var visibleActivities: [Activity] {
        if showAllActivities {
            return context.activities
        } else {
            return Array(context.activities.prefix(maxVisibleActivities))
        }
    }
}

// Placeholder in case Activity/Context aren't defined
#if DEBUG
struct ContextView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Normal context
            ContextView(context: mockFullContext)
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                .previewLayout(.sizeThatFits)
            
            // Empty context
            ContextView(context: mockEmptyContext)
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                .previewLayout(.sizeThatFits)
        }
    }
    
    static var mockFullContext: Context {
        Context(
            id: UUID(),
            timestamp: Date(),
            summary: "Working on SwiftUI project with multiple views",
            activities: [
                Activity(type: .keystroke, timestamp: Date(), application: "Xcode", bundleIdentifier: "com.apple.dt.Xcode", content: "struct ContentView: View {"),
                Activity(type: .applicationSwitch, timestamp: Date(), application: "Safari", bundleIdentifier: "com.apple.Safari", content: nil),
                Activity(type: .screenContent, timestamp: Date(), application: "Finder", bundleIdentifier: "com.apple.finder", content: "Project files and folders")
            ],
            keywords: ["SwiftUI", "Xcode", "Development"],
            mainApplication: "Xcode"
        )
    }
    
    static var mockEmptyContext: Context {
        Context(
            id: UUID(),
            timestamp: Date(),
            summary: "No activity recorded yet",
            activities: [],
            keywords: [],
            mainApplication: nil
        )
    }
}
#endif
