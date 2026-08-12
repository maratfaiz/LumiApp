import SwiftData
import SwiftUI

/// F30 — что у пользователя реально есть: расходуемые бустеры с остатком,
/// открытые техники (их отсюда можно запустить) и образы Луми, которые
/// можно надеть или снять прямо здесь.
struct InventoryView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    @State private var openTechnique: ShopItem?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    private var unlockedTechniques: [ShopItem] {
        ShopCatalog.secretTechniques.filter { ShopService.isOwned($0, progress: progress) }
    }

    private var ownedSkins: [ShopItem] {
        ShopCatalog.accessories.filter { ShopService.isOwned($0, progress: progress) }
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 16) {
                Text("Инвентарь")
                    .font(.lumiScreenTitle(22))
                    .foregroundStyle(Color.white)

                SectionLabel(text: "Бустеры")
                boosterRow

                SectionLabel(text: "Техники")
                techniquesSection

                SectionLabel(text: "Образы")
                skinsSection
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openTechnique) { item in
            TechniqueScreen(item: item)
        }
    }

    // MARK: Boosters

    private var boosterRow: some View {
        HStack(spacing: 8) {
            ForEach(ShopCatalog.boosters) { item in
                let count = ShopService.ownedCount(item, progress: progress) ?? 0
                VStack(spacing: 6) {
                    ShopItemArtwork(item: item, size: 40)
                        .opacity(count > 0 ? 1 : 0.35)
                    Text("\(count)")
                        .font(.lumi(16, weight: .heavy))
                        .foregroundStyle(count > 0 ? Color.white : LumiColor.textDim)
                    Text(item.title)
                        .font(.lumi(9.5, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 6)
                .lumiCard(fill: LumiColor.cardFillLight, radius: 14)
            }
        }
    }

    // MARK: Techniques

    @ViewBuilder private var techniquesSection: some View {
        if unlockedTechniques.isEmpty {
            emptyHint("Техники открываются в магазине — каждая добавляет свою практику.")
        } else {
            VStack(spacing: 8) {
                ForEach(unlockedTechniques) { item in
                    Button {
                        openTechnique = item
                    } label: {
                        HStack(spacing: 12) {
                            ShopItemArtwork(item: item, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.lumi(13, weight: .heavy))
                                    .foregroundStyle(Color.white)
                                Text("Открыть практику")
                                    .font(.lumi(11, weight: .semibold))
                                    .foregroundStyle(LumiColor.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LumiColor.textBright)
                        }
                        .padding(12)
                    }
                    .buttonStyle(.lumiPlain)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LumiColor.cardFillLight))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LumiColor.cardBorder, lineWidth: 1))
                }
            }
        }
    }

    // MARK: Skins

    @ViewBuilder private var skinsSection: some View {
        if ownedSkins.isEmpty {
            emptyHint("Пока нет ни одного образа — их можно купить в магазине или открыть за уроки.")
        } else {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ownedSkins) { item in
                    let equipped = ShopService.isEquipped(item, progress: progress)
                    Button {
                        equip(item)
                    } label: {
                        VStack(spacing: 6) {
                            Image(item.skinAssetName ?? "")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 72)
                            Text(item.title)
                                .font(.lumi(11, weight: .bold))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                            Text(equipped ? "надет · снять" : "надеть")
                                .font(.lumi(10, weight: .semibold))
                                .foregroundStyle(equipped ? LumiColor.yellow : LumiColor.textSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.lumiPlain)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(equipped ? LumiColor.yellow.opacity(0.12) : LumiColor.cardFillLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(equipped ? LumiColor.yellow : LumiColor.cardBorder, lineWidth: equipped ? 2 : 1)
                    )
                }
            }
        }
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.lumi(12, weight: .semibold))
            .foregroundStyle(LumiColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(Color.white.opacity(0.15))
            )
    }

    private func equip(_ item: ShopItem) {
        guard let progress else { return }
        ShopService.toggleEquip(item, progress: progress)
        WidgetSync.refresh()
    }
}

#Preview {
    NavigationStack { InventoryView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
