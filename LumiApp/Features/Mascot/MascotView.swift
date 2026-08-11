import SwiftUI

/// Renders the mascot artwork for a given emotional state, using the real
/// poses from docs/design/prototype/assets/mascot-*.png (imported into
/// Assets.xcassets) — no more SF Symbol placeholders for these 5 states.
///
/// The prototype has ~27 contextual poses, one per screen, but MascotState
/// only models 5 general states; the mapping below picks the closest-fit
/// pose per state (see each case's comment). `.dayMissed` and
/// `.innerCritic` in particular are a best-effort match rather than a
/// design-confirmed choice — flag for design review before shipping,
/// especially against the stated anti-patterns (Lumi_App_Structure.docx
/// §7: no confetti/trophies on `.innerCritic`, no exaggerated emotion, no
/// "looking down on the user" poses).
struct MascotView: View {
    let state: MascotState

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(accessibilityLabel)
    }

    private var assetName: String {
        switch state {
        case .neutral: return "mascot-home" // "звезда в наушниках" — calm, attentive default
        case .success: return "mascot-ex7" // "звезда хлопает" — clapping, the clearest success pose available
        case .dayMissed: return "mascot-ex2" // "звезда грустная" — only wistful (non-exaggerated) pose available; needs design sign-off
        case .innerCritic: return "mascot-ex1" // "звезда с блокнотом" — reflective/journaling tone, not sad or mocking
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
    MascotView(state: .success)
        .frame(width: 120, height: 120)
}
