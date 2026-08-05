import SwiftData
import SwiftUI

/// F30 — separate from Profile: equipped skin, freeze count, and the full
/// accessory grid with locked ("empty") slots for what's not owned yet.
struct InventoryView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryCard

                Text("Аксессуары").font(.lumiHeadline)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ShopCatalog.accessories) { item in
                        slot(for: item)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Инвентарь")
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Экипировано").font(.lumiCaption).foregroundStyle(.secondary)
                Text(equippedTitle).font(.lumiBody.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Заморозки").font(.lumiCaption).foregroundStyle(.secondary)
                Label("\(progress?.streakFreezesAvailable ?? 0)", systemImage: "snowflake")
                    .foregroundStyle(LumiColor.accent)
            }
        }
        .padding()
        .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 16))
    }

    private var equippedTitle: String {
        guard let equippedID = progress?.equippedMascotSkinID,
              let item = ShopCatalog.accessories.first(where: { $0.id == equippedID }) else {
            return "Без образа"
        }
        return item.title
    }

    @ViewBuilder private func slot(for item: ShopItem) -> some View {
        let owned = isOwned(item)
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(owned ? LumiColor.accentSoft : Color(.systemGray6))
                    .frame(width: 72, height: 72)
                if owned {
                    MascotView(state: .neutral).frame(width: 44, height: 44)
                } else {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary)
                }
            }
            Text(item.title)
                .font(.lumiCaption)
                .lineLimit(1)
                .foregroundStyle(owned ? .primary : .secondary)
        }
        .onTapGesture {
            if owned { equip(item) }
        }
    }

    private func isOwned(_ item: ShopItem) -> Bool {
        guard let progress else { return false }
        if case .lessonsCompleted(let required) = item.unlock {
            return progress.completedLessonIDs.count >= required || progress.unlockedMascotSkinIDs.contains(item.id)
        }
        return progress.unlockedMascotSkinIDs.contains(item.id)
    }

    private func equip(_ item: ShopItem) {
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        existing.equippedMascotSkinID = item.id
    }
}

#Preview {
    NavigationStack { InventoryView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
