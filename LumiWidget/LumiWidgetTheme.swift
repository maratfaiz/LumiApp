import SwiftUI
import UIKit

/// Widget-side theme. The colour tokens themselves come from the app's
/// `LumiColor` (that file is compiled into this target too — see
/// project.yml), so the widgets can never drift from the app's palette;
/// only the widget-specific gradients and the icon helper live here.
enum LumiWidgetGradient {
    static let streakWarm = LinearGradient(
        colors: [LumiColor.orange1, LumiColor.orange2],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Same shape as the app's background gradient, scaled to widget size.
    static let deep = RadialGradient(
        colors: [LumiColor.bgGlow, LumiColor.bgDeep],
        center: UnitPoint(x: 0.2, y: 0.0),
        startRadius: 0,
        endRadius: 260
    )
}

/// Widget-target counterpart to the app's `LumiIcon`: renders one of the
/// Phosphor icons from this target's own asset catalog (a widget extension
/// has its own bundle and can't reach the app's), template-tinted, with an
/// SF Symbol fallback.
struct WidgetIcon: View {
    var name: String
    var systemFallback: String
    var size: CGFloat
    var color: Color

    private var isAvailable: Bool { UIImage(named: name) != nil }

    var body: some View {
        if isAvailable {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(color)
        } else {
            Image(systemName: systemFallback)
                .font(.system(size: size * 0.82, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
        }
    }
}

/// Static counterpart to the app's `StarField` — widgets render frozen
/// snapshots, so this skips the twinkle animation and places the same
/// sparkle dots at fixed opacities.
struct WidgetStarSpec {
    let size: CGFloat
    let color: Color
    /// Fractions of the container's width/height.
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
}

struct WidgetStarField: View {
    let stars: [WidgetStarSpec]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(stars.enumerated()), id: \.offset) { _, star in
                    Image(systemName: "sparkle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: star.size, height: star.size)
                        .foregroundStyle(star.color)
                        .opacity(star.opacity)
                        .position(x: geo.size.width * star.x, y: geo.size.height * star.y)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

enum WidgetStarPresets {
    /// Kept clear of the mascot corner in each layout.
    static let mediumDeep: [WidgetStarSpec] = [
        .init(size: 11, color: LumiColor.purple1, x: 0.08, y: 0.16, opacity: 0.5),
        .init(size: 7, color: .white, x: 0.32, y: 0.82, opacity: 0.3),
        .init(size: 8, color: LumiColor.purpleLighter, x: 0.05, y: 0.58, opacity: 0.4),
        .init(size: 6, color: .white, x: 0.20, y: 0.10, opacity: 0.32),
    ]

    static let smallDeep: [WidgetStarSpec] = [
        .init(size: 9, color: LumiColor.purple1, x: 0.16, y: 0.10, opacity: 0.5),
        .init(size: 6, color: .white, x: 0.08, y: 0.46, opacity: 0.32),
        .init(size: 7, color: LumiColor.purpleLighter, x: 0.22, y: 0.86, opacity: 0.36),
    ]
}
