import SwiftUI

/// F1 — logo, mascot, one-line pitch, "Начать" button.
struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            MascotView(state: .neutral)
                .frame(width: 160, height: 160)
            Text("Луми")
                .font(.lumiTitle)
            Text("Короткие ежедневные занятия для здоровой самооценки")
                .font(.lumiBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button("Начать", action: onContinue)
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
                .padding(.bottom, 32)
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
