import SwiftUI

/// Renders the mascot artwork for a given emotional state. Actual artwork
/// isn't finalized yet (Lumi_Project_Handover.docx §7: "визуал ещё не
/// подтверждён") — falls back to an SF Symbol placeholder per state so the
/// app is runnable before assets land.
struct MascotView: View {
    let state: MascotState

    var body: some View {
        Image(systemName: symbolName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(LumiColor.accent)
            .accessibilityLabel(accessibilityLabel)
    }

    private var symbolName: String {
        switch state {
        case .neutral: return "star"
        case .success: return "star.fill"
        case .dayMissed: return "star.slash"
        case .innerCritic: return "shield.fill"
        case .achievement: return "sparkles"
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
