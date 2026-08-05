import SwiftUI

/// F22 — mascot skin picker, rarity-filtered. TODO(task: Build Wardrobe
/// screen wired to skin-*.png assets): bring the 9 skin images from
/// docs/design/prototype/assets into the app target and build the picker
/// grid — this is a placeholder stub so Home/Profile can link to it now.
struct WardrobeView: View {
    var body: some View {
        VStack(spacing: 16) {
            MascotView(state: .neutral).frame(width: 100, height: 100)
            Text("Гардероб").font(.lumiHeadline)
            Text("Скоро здесь появится выбор образа для Луми.")
                .font(.lumiBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .navigationTitle("Гардероб")
    }
}

#Preview {
    NavigationStack { WardrobeView() }
}
