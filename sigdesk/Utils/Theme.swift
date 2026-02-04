//
//  Theme.swift
//  sigdesk
//
//  Matches SignalDesk web app: tailwind base, accent, text.
//

import SwiftUI

enum SignalDeskTheme {
    // Base (from tailwind base)
    static let baseBg = Color(hex: "0B0B0F")
    static let baseSurface = Color(hex: "1A1A1F")
    static let baseBorder = Color(hex: "27272F")
    static let baseHover = Color(hex: "2E2E38")

    // Accent (from globals.css)
    static let accent = Color(hex: "7C3AED")
    static let accentHover = Color(hex: "6D28D9")
    static let accentLight = Color(hex: "7C3AED").opacity(0.1)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "B4B4B8")
    static let textMuted = Color(hex: "6E6E73")

    // Chat area (from web: #111114, #0e0e11, #1a1a1d)
    static let chatHeaderBg = Color(hex: "111114")
    static let chatMessageBg = Color(hex: "0E0E11")
    static let chatInputBg = Color(hex: "111114")
    static let chatInputFieldBg = Color(hex: "1A1A1D")
    static let whiteOver5 = Color.white.opacity(0.05)
    static let whiteOver10 = Color.white.opacity(0.1)
}
