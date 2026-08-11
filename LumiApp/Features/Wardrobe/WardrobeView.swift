import SwiftData
import SwiftUI

/// F22 — Кастомизация / Гардероб: mascot skin picker filterable by rarity.
/// Owned skins can be equipped directly; locked ones deep-link to the Shop
/// (Lumi_App_Structure.docx: the Home wardrobe card "ведёт в
/// кастомизацию/магазин").
struct WardrobeView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    @State private var rarityFilter: AccessoryRarity?
    @State private var showShop = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            preview

            Picker("Редкость", selection: $rarityFilter) {
                Text("Все").tag(AccessoryRarity?.none)
                ForEach(AccessoryRarity.allCases) { rarity in
                    Text(rarity.rawValue).tag(AccessoryRarity?.some(rarity))
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredAccessories) { item in
                        card(for: item)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Гардероб")
        .navigationDestination(isPresented: $showShop) { ShopView() }
    }

    private var preview: some View {
        EquippedMascotView()
            .frame(width: 140, height: 140)
            .padding(.top, 16)
    }

    private var filteredAccessories: [ShopItem] {
        guard let rarityFilter else { return ShopCatalog.accessories }
        return ShopCatalog.accessories.filter { $0.rarity == rarityFilter }
    }

    @ViewBuilder private func card(for item: ShopItem) -> some View {
        let owned = isOwned(item)
        let equipped = progress?.equippedMascotSkinID == item.id
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(equipped ? LumiColor.accent.opacity(0.25) : LumiColor.accentSoft)
                    .frame(height: 90)
                if owned, let assetName = item.skinAssetName {
                    Image(assetName).resizable().scaledToFit().padding(8)
                } else {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                }
            }
            Text(item.title).font(.lumiCaption).lineLimit(1)
            if let rarity = item.rarity {
                Text(rarity.rawValue).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .onTapGesture {
            if owned {
                progress?.equippedMascotSkinID = item.id
            } else {
                showShop = true
            }
        }
    }

    private func isOwned(_ item: ShopItem) -> Bool {
        guard let progress else { return false }
        if case .lessonsCompleted(let required) = item.unlock {
            return progress.completedLessonIDs.count >= required || progress.unlockedMascotSkinIDs.contains(item.id)
        }
        return progress.unlockedMascotSkinIDs.contains(item.id)
    }
}

#Preview {
    NavigationStack { WardrobeView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
