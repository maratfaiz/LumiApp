import SwiftData
import SwiftUI

/// F30 — separate from Profile: equipped skin, freeze/booster counts, and
/// the full accessory grid with dashed "empty" slots for what isn't owned
/// yet, as in the design's inventory screen.
struct InventoryView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 10)]

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 14) {
                Text("Инвентарь")
                    .font(.lumiScreenTitle(22))
                    .foregroundStyle(Color.white)

                summaryTiles

                SectionLabel(text: "Аксессуары")

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(ShopCatalog.accessories) { item in
                        slot(for: item)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryTiles: some View {
        HStack(spacing: 8) {
            summaryTile(
                icon: "icon-freeze",
                fallback: "snowflake",
                value: "\(progress?.streakFreezesAvailable ?? 0)",
                label: "Заморозки",
                color: LumiColor.blueChip
            )
            summaryTile(
                icon: "icon-plus",
                fallback: "plus",
                value: "\(progress?.extraDailyTaskTokens ?? 0)",
                label: "Доп. задания",
                color: LumiColor.purpleLight
            )
            summaryTile(
                icon: "icon-hint",
                fallback: "lightbulb.fill",
                value: "\(progress?.lessonHintTokens ?? 0)",
                label: "Подсказки",
                color: LumiColor.yellow
            )
        }
    }

    private func summaryTile(icon: String, fallback: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            LumiIcon(name: icon, size: 16, fallbackSystemImage: fallback).foregroundStyle(color)
            Text(value).font(.lumi(16, weight: .heavy)).foregroundStyle(color)
            Text(label).font(.lumi(10, weight: .semibold)).foregroundStyle(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .lumiAccentCard(color, radius: 14)
    }

    @ViewBuilder
    private func slot(for item: ShopItem) -> some View {
        let owned = isOwned(item)
        let equipped = progress?.equippedMascotSkinID == item.id

        Button {
            if owned { equip(item) }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if owned, let skin = item.skinAssetName {
                        Image(skin).resizable().scaledToFit().padding(8)
                    } else {
                        LumiIcon(name: "icon-lock", size: 18, fallbackSystemImage: "lock.fill")
                            .foregroundStyle(LumiColor.textDim)
                    }
                }
                .frame(height: 72)
                .frame(maxWidth: .infinity)

                Text(owned ? item.title : "пусто")
                    .font(.lumi(11, weight: .bold))
                    .foregroundStyle(owned ? Color.white : LumiColor.textDim)
                    .lineLimit(1)
                if equipped {
                    Text("экипировано")
                        .font(.lumi(10, weight: .semibold))
                        .foregroundStyle(LumiColor.purpleLight)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(equipped ? LumiColor.purple1.opacity(0.18) : (owned ? LumiColor.cardFillLight : LumiColor.cardFillFaint))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    equipped ? LumiColor.purple1 : Color.white.opacity(owned ? 0.1 : 0.12),
                    style: StrokeStyle(lineWidth: equipped ? 2 : 1, dash: owned ? [] : [4])
                )
        )
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
        WidgetSync.refresh()
    }
}

#Preview {
    NavigationStack { InventoryView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
