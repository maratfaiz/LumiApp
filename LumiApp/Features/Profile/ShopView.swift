import SwiftData
import SwiftUI

/// F13 — streak freeze, mascot skins, secret techniques. Cosmetic/convenience
/// only, enforced at the catalog level in Core/Persistence/ShopCatalog.
struct ShopView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    private let items: [ShopItem] = [
        ShopItem(id: "streak-freeze", title: "Заморозка дня", kind: .streakFreeze, priceLumens: GamificationRules.streakFreezePriceLumens),
        ShopItem(id: "secret-technique", title: "Секретная техника", kind: .secretTechnique, priceLumens: GamificationRules.secretTechniquePriceLumens),
    ]

    var body: some View {
        List(items) { item in
            HStack {
                Text(item.title)
                Spacer()
                Button("\(item.priceLumens) 💎") { purchase(item) }
                    .disabled(!canAfford(item))
            }
        }
        .navigationTitle("Магазин")
    }

    private func canAfford(_ item: ShopItem) -> Bool {
        (progress?.lumens ?? 0) >= item.priceLumens
    }

    private func purchase(_ item: ShopItem) {
        guard let progress, canAfford(item) else { return }
        progress.lumens -= item.priceLumens
        if item.kind == .streakFreeze {
            progress.streakFreezesAvailable = min(
                progress.streakFreezesAvailable + 1,
                GamificationRules.maxStoredStreakFreezes
            )
        }
    }
}

#Preview {
    NavigationStack { ShopView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
