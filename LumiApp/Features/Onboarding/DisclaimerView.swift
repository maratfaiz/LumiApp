import SwiftUI

/// F2 — mandatory, cannot be dismissed by swipe/tap-outside/back gesture,
/// only by tapping the acknowledge button (Lumi_Acceptance_Criteria.docx).
struct DisclaimerView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "info.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(LumiColor.accent)
            Text("Луми не заменяет терапию и не ставит диагнозы")
                .font(.lumiHeadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Понятно, продолжить", action: onAcknowledge)
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
                .padding(.bottom, 32)
        }
        // Intentionally no .interactiveDismissDisabled swipe/tap-outside handling
        // needed here since this is a plain pushed view, not a sheet — if this
        // is later presented as a sheet, add .interactiveDismissDisabled(true).
    }
}

#Preview {
    DisclaimerView(onAcknowledge: {})
}
