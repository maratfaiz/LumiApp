import SwiftData
import SwiftUI

/// F13 — 4 categories (Популярное / Аксессуары / Секретные техники /
/// Бустеры). Cosmetic/convenience only, except "Подсказка в уроке" — a
/// documented, deliberate pay-to-win exception (see ShopCatalog.swift).
/// Layout ported from the design's shop screen: category tiles on top,
/// item grid below.
struct ShopView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    @State private var category: ShopCategory = .featured

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 18) {
                header
                categoryTiles

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 12) {
                    ForEach(ShopCatalog.items(in: category)) { item in
                        itemCard(item)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Магазин")
                .font(.lumiScreenTitle(22))
                .foregroundStyle(Color.white)
            Spacer()
            HStack(spacing: 5) {
                LumiIcon(name: "icon-lumen", size: 14, fallbackSystemImage: "star.fill")
                Text("\(progress?.lumens ?? 0)")
            }
            .font(.lumi(12, weight: .heavy))
            .foregroundStyle(LumiColor.yellow)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(LumiColor.yellow.opacity(0.12)))
            .overlay(Capsule().stroke(LumiColor.yellow.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: Categories

    private var categoryTiles: some View {
        HStack(spacing: 10) {
            ForEach(ShopCategory.allCases) { value in
                let isActive = category == value
                let tint = categoryColor(value)
                Button {
                    category = value
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isActive ? tint.opacity(0.16) : LumiColor.cardFillLight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isActive ? tint : LumiColor.cardBorder, lineWidth: isActive ? 1.5 : 1)
                                )
                                .frame(width: 52, height: 52)
                            LumiGlyph(name: categoryIcon(value), size: 20)
                                .foregroundStyle(isActive ? tint : LumiColor.textBody)
                        }
                        Text(value.rawValue)
                            .font(.lumi(10.5, weight: isActive ? .heavy : .bold))
                            .foregroundStyle(isActive ? tint : LumiColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func categoryIcon(_ value: ShopCategory) -> String {
        switch value {
        case .featured: return "star.fill"
        case .accessories: return "icon-glasses"
        case .secretTechniques: return "icon-journal"
        case .boosters: return "icon-bolt"
        }
    }

    private func categoryColor(_ value: ShopCategory) -> Color {
        switch value {
        case .featured: return LumiColor.yellow
        case .accessories: return Color(hex: 0x5B9FFF)
        case .secretTechniques: return LumiColor.purpleLight
        case .boosters: return LumiColor.blueChip
        }
    }

    // MARK: Items

    @ViewBuilder
    private func itemCard(_ item: ShopItem) -> some View {
        let owned = isOwned(item)
        let equipped = isEquipped(item)
        let tint = rarityColor(item)

        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.5), lineWidth: 1.5))
                    .aspectRatio(1, contentMode: .fit)

                if let skin = item.skinAssetName {
                    Image(skin)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    LumiGlyph(name: itemIcon(item), size: 20)
                        .foregroundStyle(tint)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let rarity = item.rarity {
                    Text(rarity.rawValue.uppercased())
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x0A1A33))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(tint)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(x: 4, y: 4)
                }

                if !owned {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: 0x0A0819).opacity(0.5))
                        .overlay(
                            LumiIcon(name: "icon-lock", size: 18, fallbackSystemImage: "lock.fill")
                                .foregroundStyle(LumiColor.textTertiary)
                        )
                        .aspectRatio(1, contentMode: .fit)
                }
            }

            Text(item.title)
                .font(.lumi(10.5, weight: .bold))
                .foregroundStyle(LumiColor.textBright)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 26, alignment: .top)

            action(for: item, owned: owned, equipped: equipped)
        }
    }

    @ViewBuilder
    private func action(for item: ShopItem, owned: Bool, equipped: Bool) -> some View {
        if owned {
            if item.skinAssetName != nil {
                Button {
                    equip(item)
                } label: {
                    Text(equipped ? "Надет" : "Надеть")
                        .font(.lumi(10, weight: .heavy))
                        .foregroundStyle(equipped ? LumiColor.yellow : LumiColor.blueChip)
                }
                .buttonStyle(.plain)
                .disabled(equipped)
            } else {
                Text("Есть")
                    .font(.lumi(10, weight: .heavy))
                    .foregroundStyle(LumiColor.green)
            }
        } else {
            switch item.unlock {
            case .lumens(let price):
                Button {
                    purchase(item, price: price)
                } label: {
                    HStack(spacing: 3) {
                        LumiIcon(name: "icon-lumen", size: 9, fallbackSystemImage: "star.fill")
                        Text("\(price)")
                    }
                    .font(.lumi(11, weight: .heavy))
                    .foregroundStyle(canAfford(price) ? LumiColor.yellow : LumiColor.textDim)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford(price))
            case .lessonsCompleted(let required):
                Text("\(progress?.completedLessonIDs.count ?? 0)/\(required) уроков")
                    .font(.lumi(9, weight: .bold))
                    .foregroundStyle(LumiColor.textDim)
            }
        }
    }

    private func itemIcon(_ item: ShopItem) -> String {
        switch item.id {
        case "booster-streak-freeze": return "icon-freeze"
        case "booster-extra-task": return "icon-plus"
        case "booster-lesson-hint": return "icon-hint"
        case "technique-self-embrace": return "icon-selfhug"
        case "technique-emotion-diary": return "icon-journal"
        case "technique-values-focus": return "icon-target"
        default:
            switch item.category {
            case .accessories, .featured: return "icon-glasses"
            case .secretTechniques: return "icon-journal"
            case .boosters: return "icon-bolt"
            }
        }
    }

    private func rarityColor(_ item: ShopItem) -> Color {
        switch item.rarity {
        case .common: return LumiColor.textSecondary
        case .rare: return Color(hex: 0x5B9FFF)
        case .epic: return Color(hex: 0xFF6EC7)
        case nil: return LumiColor.purpleLight
        }
    }

    // MARK: State

    private func canAfford(_ price: Int) -> Bool {
        (progress?.lumens ?? 0) >= price
    }

    private func isOwned(_ item: ShopItem) -> Bool {
        guard let progress else { return false }
        switch item.category {
        case .accessories:
            if case .lessonsCompleted(let required) = item.unlock {
                return progress.completedLessonIDs.count >= required || progress.unlockedMascotSkinIDs.contains(item.id)
            }
            return progress.unlockedMascotSkinIDs.contains(item.id)
        case .secretTechniques:
            return progress.unlockedSecretTechniqueIDs.contains(item.id)
        case .boosters, .featured:
            return false // boosters are consumable, never "owned" outright
        }
    }

    private func isEquipped(_ item: ShopItem) -> Bool {
        progress?.equippedMascotSkinID == item.id
    }

    private func equip(_ item: ShopItem) {
        progress?.equippedMascotSkinID = item.id
        WidgetSync.refresh()
    }

    private func purchase(_ item: ShopItem, price: Int) {
        guard let progress, progress.lumens >= price else { return }
        progress.lumens -= price
        switch item.id {
        case "booster-streak-freeze":
            progress.streakFreezesAvailable = min(progress.streakFreezesAvailable + 1, GamificationRules.maxStoredStreakFreezes)
        case "booster-extra-task":
            progress.extraDailyTaskTokens += 1
        case "booster-lesson-hint":
            progress.lessonHintTokens += 1
        default:
            switch item.category {
            case .accessories:
                progress.unlockedMascotSkinIDs.append(item.id)
            case .secretTechniques:
                progress.unlockedSecretTechniqueIDs.append(item.id)
            case .boosters, .featured:
                break
            }
        }
        WidgetSync.refresh()
    }
}

#Preview {
    NavigationStack { ShopView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
