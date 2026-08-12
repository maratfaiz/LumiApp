import SwiftData
import SwiftUI

/// Renders the currently-equipped wardrobe skin (F22) on the design's glow
/// disc, or falls back to the plain `MascotView` pose when nothing's
/// equipped.
struct EquippedMascotView: View {
    var state: MascotState = .neutral
    var size: CGFloat = 150

    @Query private var progresses: [UserProgress]
    private var equippedSkinID: String? { progresses.first?.equippedMascotSkinID }

    var body: some View {
        if let equippedSkinID {
            LumiMascot(
                assetName: equippedSkinID,
                size: size,
                accessibilityTitle: "Луми в образе «\(skinTitle(equippedSkinID))»"
            )
        } else {
            MascotView(state: state, size: size)
        }
    }

    private func skinTitle(_ id: String) -> String {
        ShopCatalog.accessories.first { $0.id == id }?.title ?? "Луми"
    }
}

#Preview {
    ZStack {
        LumiBackground()
        EquippedMascotView(size: 180)
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
