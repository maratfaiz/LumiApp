import SwiftData
import SwiftUI

/// F13 — 4 categories (Популярное / Аксессуары / Секретные техники /
/// Бустеры). Cosmetic/convenience only, except "Подсказка в уроке" — a
/// documented, deliberate pay-to-win exception (see ShopCatalog.swift).
struct ShopView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    @State private var category: ShopCategory = .featured

    var body: some View {
        VStack(spacing: 0) {
            Picker("Категория", selection: $category) {
                ForEach(ShopCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            List(ShopCatalog.items(in: category)) { item in
                row(for: item)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Магазин")
        .toolbar {
            if let progress {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(progress.lumens)", systemImage: "star.fill").foregroundStyle(.yellow)
                }
            }
        }
    }

    @ViewBuilder private func row(for item: ShopItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.lumiBody.bold())
                if let rarity = item.rarity {
                    Text(rarity.rawValue).font(.lumiCaption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            actionControl(for: item)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private func actionControl(for item: ShopItem) -> some View {
        if isOwned(item) {
            if item.skinAssetName != nil {
                Button(isEquipped(item) ? "Надето" : "Надеть") { equip(item) }
                    .disabled(isEquipped(item))
            } else {
                Label("Есть", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
            }
        } else {
            switch item.unlock {
            case .lumens(let price):
                Button("\(price) ★") { purchase(item, price: price) }
                    .disabled((progress?.lumens ?? 0) < price)
            case .lessonsCompleted(let required):
                let done = progress?.completedLessonIDs.count ?? 0
                Label("\(done)/\(required) уроков", systemImage: "lock.fill")
                    .font(.lumiCaption)
                    .foregroundStyle(.secondary)
            }
        }
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
    }
}

#Preview {
    NavigationStack { ShopView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
