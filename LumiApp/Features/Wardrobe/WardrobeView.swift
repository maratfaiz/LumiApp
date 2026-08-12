import SwiftData
import SwiftUI

/// F22 — Кастомизация / Гардероб: mascot skin picker with a live preview,
/// rarity filter and a "Надеть образ" CTA, ported from the design's
/// "Образы Луми" screen. Locked skins deep-link to the Shop
/// (Lumi_App_Structure.docx: the Home wardrobe card "ведёт в
/// кастомизацию/магазин").
struct WardrobeView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    @State private var rarityFilter: AccessoryRarity?
    @State private var previewSkinID: String?
    @State private var showShop = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    private var equippedSkinID: String? { progress?.equippedMascotSkinID }

    private var previewedItem: ShopItem? {
        ShopCatalog.accessories.first { $0.id == previewSkinID }
    }

    var body: some View {
        LumiScreen {
            VStack(spacing: 0) {
                Text("Образы Луми")
                    .font(.lumiScreenTitle(26))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)
                Text("Выбери образ, который отражает тебя")
                    .font(.lumi(12.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 18)

                preview
                    .padding(.bottom, 18)

                filterRow
                    .padding(.bottom, 14)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(filteredAccessories) { item in
                        skinCard(item)
                    }
                }

                if let previewedItem {
                    previewAction(for: previewedItem)
                        .padding(.top, 14)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showShop) { ShopView() }
        .onAppear {
            if previewSkinID == nil { previewSkinID = equippedSkinID }
        }
    }

    // MARK: Preview

    private var preview: some View {
        VStack(spacing: 8) {
            if let previewSkinID, previewSkinID != equippedSkinID, isOwnedID(previewSkinID) {
                LumiMascot(assetName: previewSkinID, size: 140)
            } else {
                EquippedMascotView(size: 140)
            }
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x2A1D52), Color(hex: 0x150F30)],
                        center: UnitPoint(x: 0.5, y: 0.35), startRadius: 0, endRadius: 160
                    )
                )
        )
    }

    @ViewBuilder
    private func previewAction(for item: ShopItem) -> some View {
        if ShopService.isEquipped(item, progress: progress) {
            SecondaryButton(title: "Снять образ") { toggleEquip(item) }
        } else if isOwned(item) {
            PrimaryButton(title: "Надеть образ") { toggleEquip(item) }
        } else if let block = ShopService.purchaseBlock(for: item, progress: progress) {
            VStack(spacing: 8) {
                PrimaryButton(title: buyTitle(item), isEnabled: false, action: {})
                Text(block.message)
                    .font(.lumi(11.5, weight: .semibold))
                    .foregroundStyle(LumiColor.orange1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            PrimaryButton(title: buyTitle(item)) { buy(item) }
        }
    }

    private func buyTitle(_ item: ShopItem) -> String {
        guard let price = item.priceInLumens else { return "Откроется за уроки" }
        return "Купить за \(price) ✦"
    }

    // MARK: Filter

    private var filterRow: some View {
        HStack(spacing: 6) {
            filterChip(title: "Все", value: nil)
            ForEach(AccessoryRarity.allCases) { rarity in
                filterChip(title: rarity.rawValue, value: rarity)
            }
            Spacer(minLength: 0)
        }
    }

    private func filterChip(title: String, value: AccessoryRarity?) -> some View {
        let isActive = rarityFilter == value
        return Button {
            rarityFilter = value
        } label: {
            Text(title)
                .font(.lumi(11.5, weight: isActive ? .heavy : .bold))
                .foregroundStyle(isActive ? Color.white : LumiColor.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .buttonStyle(.lumiPlain)
        .background(Capsule().fill(isActive ? LumiColor.purple1.opacity(0.3) : LumiColor.cardFillLight))
        .overlay(Capsule().stroke(isActive ? LumiColor.purple1.opacity(0.6) : LumiColor.cardBorder, lineWidth: 1))
    }

    private var filteredAccessories: [ShopItem] {
        guard let rarityFilter else { return ShopCatalog.accessories }
        return ShopCatalog.accessories.filter { $0.rarity == rarityFilter }
    }

    // MARK: Grid

    @ViewBuilder
    private func skinCard(_ item: ShopItem) -> some View {
        let owned = isOwned(item)
        let equipped = item.id == equippedSkinID
        let previewed = item.id == previewSkinID
        let tint = ShopStyle.rarityColor(item.rarity)
        let borderColor = equipped ? LumiColor.yellow : (previewed ? LumiColor.purple1 : tint.opacity(0.6))
        let fillColor = equipped ? LumiColor.yellow.opacity(0.1) : (previewed ? LumiColor.purple1.opacity(0.14) : tint.opacity(0.08))

        Button {
            previewSkinID = item.id
        } label: {
            VStack(spacing: 5) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LumiColor.cardFillLight)
                        .aspectRatio(1, contentMode: .fit)

                    if let skin = item.skinAssetName {
                        Image(skin)
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if let rarity = item.rarity {
                        Text(rarity.rawValue.uppercased())
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x1A1530))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(tint)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .offset(x: 4, y: 4)
                    }

                    if !owned {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: 0x0A0819).opacity(0.55))
                            .overlay(
                                LumiIcon(name: "icon-lock", size: 18, fallbackSystemImage: "lock.fill")
                                    .foregroundStyle(LumiColor.textTertiary)
                            )
                            .aspectRatio(1, contentMode: .fit)
                    }

                    if equipped {
                        ZStack {
                            Circle().fill(LumiColor.yellow)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(Color(hex: 0x3A2400))
                        }
                        .frame(width: 18, height: 18)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(x: -4, y: 4)
                    }
                }

                Text(item.title)
                    .font(.lumi(10, weight: .bold))
                    .foregroundStyle(LumiColor.textBright)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 24, alignment: .top)

                Text(statusLabel(for: item, owned: owned, equipped: equipped))
                    .font(.lumi(9, weight: .bold))
                    .foregroundStyle(equipped ? LumiColor.yellow : (owned ? LumiColor.textSecondary : LumiColor.blueChip))
            }
            .padding(7)
        }
        .buttonStyle(.lumiPlain)
        .background(RoundedRectangle(cornerRadius: 12).fill(fillColor))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: equipped || previewed ? 2 : 1.5))
    }

    private func statusLabel(for item: ShopItem, owned: Bool, equipped: Bool) -> String {
        if equipped { return "Надет" }
        if owned { return "Доступен" }
        switch item.unlock {
        case .lessonsCompleted(let required):
            return "\(progress?.completedLessonIDs.count ?? 0)/\(required) уроков"
        case .lumens(let price):
            return "\(price) ✦"
        }
    }

    private func isOwnedID(_ id: String) -> Bool {
        guard let item = ShopCatalog.accessories.first(where: { $0.id == id }) else { return false }
        return isOwned(item)
    }

    private func isOwned(_ item: ShopItem) -> Bool {
        ShopService.isOwned(item, progress: progress)
    }

    /// Надеть / снять — одна и та же кнопка, как в инвентаре.
    private func toggleEquip(_ item: ShopItem) {
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        ShopService.toggleEquip(item, progress: existing)
        WidgetSync.refresh()
    }

    /// Покупка прямо из гардероба — не гоняем пользователя в магазин,
    /// если у него уже хватает люменов.
    private func buy(_ item: ShopItem) {
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        if case .purchased = ShopService.purchase(item, progress: existing) {
            ShopService.toggleEquip(item, progress: existing)
            WidgetSync.refresh()
        } else {
            showShop = true
        }
    }
}

#Preview {
    NavigationStack { WardrobeView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
