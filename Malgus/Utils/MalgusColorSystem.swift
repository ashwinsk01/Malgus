//
//  MalgusColorSystem.swift
//  Malgus
//
//  Created by Ashwin SK on 30/03/2025.
//

import SwiftUI
import AppKit

extension Color {
    // MARK: - Background Colors
    
    /// Primary window background
    static let backgroundPrimary = Color(NSColor.windowBackgroundColor)
    
    /// Secondary background for panels and sections
    static let backgroundSecondary = Color(NSColor.underPageBackgroundColor)
    
    /// Background for controls and interactive elements
    static let controlBackground = Color(NSColor.controlBackgroundColor)
    
    // MARK: - Foreground/Text Colors
    
    /// Primary text color
    static let textPrimary = Color(NSColor.textColor)
    
    /// Secondary text color for subtitles and less important information
    static let textSecondary = Color(NSColor.secondaryLabelColor)
    
    /// Disabled text color
    static let textDisabled = Color(NSColor.disabledControlTextColor)
    
    // MARK: - UI Element Colors
    
    /// Separator line color
    static let separator = Color(NSColor.separatorColor)
    
    /// Grid line color
    static let grid = Color(NSColor.gridColor)
    
    // MARK: - Brand Colors
    
    /// Primary brand color - can customize
    static let brandPrimary = Color(NSColor.systemBlue)
    
    /// Secondary brand color - can customize
    static let brandSecondary = Color(NSColor.systemPurple)
    
    // MARK: - Semantic Colors
    
    /// Success color
    static let success = Color(NSColor.systemGreen)
    
    /// Warning color
    static let warning = Color(NSColor.systemYellow)
    
    /// Error color
    static let error = Color(NSColor.systemRed)
    
    /// Info color
    static let info = Color(NSColor.systemBlue)
}

