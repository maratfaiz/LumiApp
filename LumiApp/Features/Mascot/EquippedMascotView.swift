import SwiftData
import SwiftUI

/// Renders the currently-equipped wardrobe skin (F22) over the mascot, or
/// falls back to the plain MascotView placeholder when nothing's equipped.
/// Skin artwork itself is real (docs/design/prototype/assets/skin-*.png,
/// imported into Assets.xcassets); only the base mascot poses are still
/// SF Symbol placeholders (see MascotView's own doc comment).
struct EquippedMascotView: View {
    var state: MascotState = .neutral

    @Query private var progresses: [UserProgress]
    private var equippedSkinID: String? { progresses.first?.equippedMascotSkinID }

    var body: some View {
        if let equippedSkinID {
            Image(equippedSkinID)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("Луми в образе «\(skinTitle(equippedSkinID))»")
        } else {
            MascotView(state: state)
        }
    }

    private func skinTitle(_ id: String) -> String {
        ShopCatalog.accessories.first { $0.id == id }?.title ?? "Луми"
    }
}

#Preview {
    EquippedMascotView()
        .frame(width: 150, height: 150)
        .modelContainer(PersistenceController.makePreviewContainer())
}
