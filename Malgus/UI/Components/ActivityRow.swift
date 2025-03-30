//
//  ActivityRow.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct ActivityRow: View {
    let activity: Activity
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header row
            HStack {
                activityIcon
                    .foregroundColor(Color.brandPrimary)
                
                Text(activity.application)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Text(activity.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(Color.textSecondary)
                
                if hasExpandableContent && !isExpanded {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color.brandPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if hasExpandableContent {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(Color.brandPrimary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Content row - with improved text display
            if let content = activity.content, !content.isEmpty {
                if isExpanded || !needsExpansionButton(for: content) {
                    // For keystrokes, format nicely
                    if activity.type == .keystroke {
                        Text(content)
                            .font(.body)
                            .foregroundColor(Color.textPrimary)
                            .padding(8)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(6)
                    } else {
                        // For other content types
                        Text(content)
                            .font(.caption)
                            .foregroundColor(Color.textSecondary)
                            .padding(.leading)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                } else {
                    // Preview for non-expanded state
                    Text(previewText(for: content))
                        .font(activity.type == .keystroke ? .body : .caption)
                        .foregroundColor(activity.type == .keystroke ? Color.textPrimary : Color.textSecondary)
                        .padding(.leading)
                        .lineLimit(2)
                        .opacity(0.8)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make the whole row tappable
        .onTapGesture {
            if hasExpandableContent {
                isExpanded.toggle()
            }
        }
    }
    
    private var activityIcon: some View {
        Group {
            switch activity.type {
            case .keystroke:
                Image(systemName: "keyboard")
            case .screenContent:
                Image(systemName: "display")
            case .applicationSwitch:
                Image(systemName: "arrow.left.arrow.right")
            case .mouseMovement:
                Image(systemName: "cursorarrow.motionlines")
            case .browserNavigation:
                Image(systemName: "safari")
            }
        }
    }
    
    // Determine if content needs expansion button
    private var hasExpandableContent: Bool {
        guard let content = activity.content else { return false }
        return needsExpansionButton(for: content)
    }
    
    private func needsExpansionButton(for content: String) -> Bool {
        // Criteria for expansion:
        // 1. Content has more than 2 lines
        // 2. Content is longer than 100 characters
        return content.contains("\n") || content.count > 100
    }
    
    private func previewText(for content: String) -> String {
        // If content has multiple lines, show first line + ellipsis
        if content.contains("\n") {
            if let firstLine = content.components(separatedBy: .newlines).first {
                return firstLine + "..."
            }
        }
        
        // Otherwise just return a subset of the content
        if content.count > 100 {
            let endIndex = content.index(content.startIndex, offsetBy: 100)
            return String(content[..<endIndex]) + "..."
        }
        
        return content
    }
}
