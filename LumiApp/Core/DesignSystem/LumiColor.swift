import SwiftUI

/// Placeholder palette — pulled from the accent color already used in the
/// product docs' table styling (#5B4B9E). Replace once Stage 3 (UI Design /
/// Design System) produces the real tokens.
enum LumiColor {
    static let accent = Color(hex: 0x5B4B9E)
    static let accentSoft = Color(hex: 0xEDE9F7)
    static let border = Color(hex: 0xD0C8E8)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
