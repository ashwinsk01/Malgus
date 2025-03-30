//
//  RecommendationView.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI

struct RecommendationView: View {
    let text: String
    
    var body: some View {
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
            
            HStack {
                Spacer()
                
                Button(action: {}) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(Color.brandPrimary)
                }
                
                Button(action: {}) {
                    Label("Apply", systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(Color.success)
                }
            }
        }
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}
