import SwiftUI

/// F27 — swipeable affirmation cards, favorite, optional read-aloud, repeat,
/// speed control. TODO(task: Build Affirmations mode screen): full card
/// deck — this is a placeholder stub so Home can link to it now.
struct AffirmationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            MascotView(state: .neutral).frame(width: 100, height: 100)
            Text("Аффирмации").font(.lumiHeadline)
            Text("Скоро здесь появятся карточки с аффирмациями.")
                .font(.lumiBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .navigationTitle("Аффирмации")
    }
}

#Preview {
    NavigationStack { AffirmationsView() }
}
