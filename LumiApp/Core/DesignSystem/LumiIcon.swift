import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A custom UI icon from the Phosphor set shipped in `Assets.xcassets`
/// (imageset name e.g. `icon-streak`), rendered as a template so
/// `.foregroundStyle(...)` tints it exactly like the `Image(systemName:)`
/// calls it replaces. Falls back to an SF Symbol when the named asset
/// isn't in the catalog, so a missing icon degrades instead of showing an
/// empty box.
///
/// Icon artwork: Phosphor Icons (MIT) — see docs/legal/PHOSPHOR-LICENSE.txt.
struct LumiIcon: View {
    var name: String
    var size: CGFloat = 20
    var fallbackSystemImage: String = "questionmark"

    private var isAvailable: Bool {
        #if canImport(UIKit)
        return UIImage(named: name) != nil
        #else
        return false
        #endif
    }

    var body: some View {
        if isAvailable {
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: fallbackSystemImage)
                .font(.system(size: size * 0.82, weight: .semibold))
                .frame(width: size, height: size)
        }
    }
}

/// Renders either a Phosphor asset icon (`icon-…`) or an SF Symbol, chosen
/// by the name's prefix — the design mixes both freely.
struct LumiGlyph: View {
    var name: String
    var size: CGFloat = 20

    var body: some View {
        if name.hasPrefix("icon-") {
            LumiIcon(name: name, size: size)
        } else {
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold))
                .frame(width: size * 1.2, height: size * 1.2)
        }
    }
}
