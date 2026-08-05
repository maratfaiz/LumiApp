import SwiftUI

/// F29 — duration + ambient sound picker (Тишина/Дождь/Океан), session
/// timer. Ambient audio for Дождь/Океан needs licensed assets (see task:
/// Source free-licensed ambient audio + build Meditation mode screen) —
/// this is a placeholder stub so Home can link to it now.
struct MeditationView: View {
    var body: some View {
        VStack(spacing: 16) {
            MascotView(state: .neutral).frame(width: 100, height: 100)
            Text("Медитация").font(.lumiHeadline)
            Text("Скоро здесь появится выбор длительности и звука.")
                .font(.lumiBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .navigationTitle("Медитация")
    }
}

#Preview {
    NavigationStack { MeditationView() }
}
