import SwiftUI

/// The real design-system palette, ported from the approved Swift design
/// (lumidesign → `Lumi.swiftpm/Sources/Theme.swift`), which in turn matches
/// the CSS hex values of the HTML prototype in
/// `docs/design/prototype/Lumi_Prototype.dc.html`.
///
/// The app is dark-only by design — there is no light variant of these
/// tokens, and `RootView` pins `.preferredColorScheme(.dark)` accordingly.
enum LumiColor {
    // Background
    static let bgDeep = Color(hex: 0x0B0A1A)
    static let bgGlow = Color(hex: 0x241A45)
    static let bgCard = Color(hex: 0x0D0B22)

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x9C93C9)
    static let textTertiary = Color(hex: 0x8A80B0)
    static let textBody = Color(hex: 0xC9C2E6)
    static let textBright = Color(hex: 0xE5E0F7)
    static let textFaint = Color(hex: 0x6B6285)
    static let textFaint2 = Color(hex: 0x7A7099)
    static let textDim = Color(hex: 0x6A6088)

    // Brand
    static let purple1 = Color(hex: 0x8B6CF6)
    static let purple2 = Color(hex: 0x6C4FE0)
    static let purpleLight = Color(hex: 0xC3B3FF)
    static let purpleLighter = Color(hex: 0xB39DFF)

    // Accents
    static let danger = Color(hex: 0xFF5A5A)
    static let orange1 = Color(hex: 0xFFB37A)
    static let orange2 = Color(hex: 0xFF7A4D)
    static let yellow = Color(hex: 0xFFD166)
    static let green = Color(hex: 0x4ADE80)
    static let blueChip = Color(hex: 0x8FC3FF)
    static let blueStrong = Color(hex: 0x5AAAFF)

    // Surfaces
    static let cardFill = Color.white.opacity(0.06)
    static let cardFillLight = Color.white.opacity(0.05)
    static let cardFillFaint = Color.white.opacity(0.04)
    static let cardBorder = Color.white.opacity(0.1)
    static let cardBorderStrong = Color.white.opacity(0.12)
}

extension Color {
    /// Creates a color from a 0xRRGGBB hex literal, matching the design's
    /// CSS hex colors.
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
