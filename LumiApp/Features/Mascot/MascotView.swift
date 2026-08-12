import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Mascot artwork on the design's soft purple glow disc — the
/// `<image-slot>` treatment every mascot gets in the prototype.
///
/// Falls back to a gradient disc when the named asset isn't in the catalog,
/// so a missing pose degrades gracefully instead of rendering an empty box.
struct LumiMascot: View {
    var assetName: String?
    var size: CGFloat = 150
    var fallbackSystemImage: String = "sparkles"
    var accessibilityTitle: String = "Луми"

    private var resolvedImage: Image? {
        guard let assetName else { return nil }
        #if canImport(UIKit)
        guard UIImage(named: assetName) != nil else { return nil }
        #endif
        return Image(assetName)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [LumiColor.purple1.opacity(0.35), LumiColor.purple1.opacity(0)],
                        center: .center, startRadius: 0, endRadius: size / 2
                    )
                )
            if let resolvedImage {
                resolvedImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .fill(LumiGradient.primary.opacity(0.18))
                    .frame(width: size * 0.72, height: size * 0.72)
                Circle()
                    .strokeBorder(LumiColor.purple1.opacity(0.35), lineWidth: 1.5)
                    .frame(width: size * 0.72, height: size * 0.72)
                Image(systemName: fallbackSystemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .foregroundStyle(LumiGradient.primary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement()
        .accessibilityLabel(accessibilityTitle)
    }
}

/// Renders the mascot artwork for a given emotional state, using the real
/// poses from the design (imported into Assets.xcassets).
///
/// The design has ~27 contextual poses, one per screen, but MascotState
/// only models 5 general states; the mapping below picks the closest-fit
/// pose per state (see each case's comment). `.dayMissed` and
/// `.innerCritic` in particular are a best-effort match rather than a
/// design-confirmed choice — flag for design review before shipping,
/// especially against the stated anti-patterns (Lumi_App_Structure.docx
/// §7: no confetti/trophies on `.innerCritic`, no exaggerated emotion, no
/// "looking down on the user" poses).
struct MascotView: View {
    let state: MascotState
    var size: CGFloat = 120

    var body: some View {
        LumiMascot(assetName: assetName, size: size, accessibilityTitle: accessibilityLabel)
    }

    private var assetName: String {
        switch state {
        case .neutral: return "mascot-home" // "звезда в наушниках" — calm, attentive default
        case .success: return "mascot-joy" // "звезда радуется" — the design's own success pose
        case .dayMissed: return "mascot-sleeping" // "звезда спит" — gentle, non-punitive absence
        case .innerCritic: return "mascot-ex1" // "звезда с блокнотом" — reflective, not sad or mocking
        case .achievement: return "mascot-ex9" // "звезда с ракетой" — bigger celebratory beat than plain success
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .neutral: return "Луми"
        case .success: return "Луми радуется успеху"
        case .dayMissed: return "Луми мягко напоминает о пропуске дня"
        case .innerCritic: return "Луми поддерживает во время внутренней критики"
        case .achievement: return "Луми празднует достижение"
        }
    }
}

#Preview {
    ZStack {
        LumiBackground()
        MascotView(state: .success, size: 180)
    }
}
