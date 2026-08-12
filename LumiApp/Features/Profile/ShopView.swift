import SwiftData
import SwiftUI

/// F13 — 4 категории (Популярное / Аксессуары / Секретные техники /
/// Бустеры). Покупка реальная: люмены списываются, предмет попадает в
/// инвентарь, расходуемые показывают остаток. Вся логика — в `ShopService`,
/// экран только показывает её и подтверждает действие.
struct ShopView: View {
    @Query private var progresses: [UserProgress]
    @Environment(\.modelContext) private var modelContext
    private var progress: UserProgress? { progresses.first }

    @State private var category: ShopCategory = .featured
    @State private var selectedItem: ShopItem?
    @State private var toast: ShopToast?

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 18) {
                header
                categoryTiles

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 14) {
                    ForEach(ShopCatalog.items(in: category)) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            ShopItemCard(item: item, progress: progress)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            ShopItemSheet(
                item: item,
                progress: progress,
                onBuy: { buy(item) },
                onToggleEquip: { toggleEquip(item) }
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(LumiColor.bgDeep)
        }
        .overlay(alignment: .bottom) {
            if let toast {
                ShopToastView(toast: toast)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: toast)
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
                    .contentTransition(.numericText())
            }
            .font(.lumi(12, weight: .heavy))
            .foregroundStyle(LumiColor.yellow)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(LumiColor.yellow.opacity(0.12)))
            .overlay(Capsule().stroke(LumiColor.yellow.opacity(0.3), lineWidth: 1))
            .accessibilityLabel("Баланс: \(progress?.lumens ?? 0) люменов")
        }
    }

    // MARK: Categories

    private var categoryTiles: some View {
        HStack(spacing: 10) {
            ForEach(ShopCategory.allCases) { value in
                let isActive = category == value
                let tint = ShopStyle.categoryColor(value)
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
                            LumiGlyph(name: ShopStyle.categoryIcon(value), size: 20)
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

    // MARK: Actions

    private func buy(_ item: ShopItem) {
        let target = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()

        switch ShopService.purchase(item, progress: target) {
        case .purchased(let spent):
            selectedItem = nil
            show(ShopToast(text: "«\(item.title)» куплено · −\(spent)", isError: false))
            WidgetSync.refresh()
        case .blocked(let block):
            show(ShopToast(text: block.message, isError: true))
        }
    }

    private func toggleEquip(_ item: ShopItem) {
        guard let progress else { return }
        let wasEquipped = ShopService.isEquipped(item, progress: progress)
        ShopService.toggleEquip(item, progress: progress)
        selectedItem = nil
        show(ShopToast(text: wasEquipped ? "Образ снят" : "Луми надел «\(item.title)»", isError: false))
        WidgetSync.refresh()
    }

    private func show(_ newToast: ShopToast) {
        toast = newToast
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if toast == newToast { toast = nil }
        }
    }
}

// MARK: - Toast

struct ShopToast: Equatable {
    let text: String
    let isError: Bool
}

private struct ShopToastView: View {
    let toast: ShopToast

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
            Text(toast.text)
                .font(.lumi(12.5, weight: .bold))
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(toast.isError ? LumiColor.danger.opacity(0.9) : LumiColor.purple2.opacity(0.95))
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
        .padding(.horizontal, 20)
    }
}

// MARK: - Shared item styling

enum ShopStyle {
    static func categoryIcon(_ value: ShopCategory) -> String {
        switch value {
        case .featured: return "star.fill"
        case .accessories: return "icon-glasses"
        case .secretTechniques: return "icon-journal"
        case .boosters: return "icon-bolt"
        }
    }

    static func categoryColor(_ value: ShopCategory) -> Color {
        switch value {
        case .featured: return LumiColor.yellow
        case .accessories: return Color(hex: 0x5B9FFF)
        case .secretTechniques: return LumiColor.purpleLight
        case .boosters: return LumiColor.blueChip
        }
    }

    static func rarityColor(_ rarity: AccessoryRarity?) -> Color {
        switch rarity {
        case .common: return LumiColor.textSecondary
        case .rare: return Color(hex: 0x5B9FFF)
        case .epic: return Color(hex: 0xFF6EC7)
        case nil: return LumiColor.purpleLight
        }
    }
}

/// Картинка товара: скин целиком для аксессуаров, цветная иллюстрация для
/// бустеров и техник.
struct ShopItemArtwork: View {
    let item: ShopItem
    var size: CGFloat = 56

    var body: some View {
        if let skin = item.skinAssetName {
            Image(skin).resizable().scaledToFit().frame(width: size, height: size)
        } else if let icon = item.iconAssetName {
            Image(icon).resizable().scaledToFit().frame(width: size, height: size)
        } else {
            LumiGlyph(name: ShopStyle.categoryIcon(item.category), size: size * 0.5)
                .foregroundStyle(ShopStyle.rarityColor(item.rarity))
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Grid card

private struct ShopItemCard: View {
    let item: ShopItem
    let progress: UserProgress?

    private var owned: Bool { ShopService.isOwned(item, progress: progress) }
    private var equipped: Bool { ShopService.isEquipped(item, progress: progress) }
    private var count: Int? { ShopService.ownedCount(item, progress: progress) }

    var body: some View {
        let tint = ShopStyle.rarityColor(item.rarity)

        VStack(spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(0.5), lineWidth: 1.5))
                    .aspectRatio(1, contentMode: .fit)

                ShopItemArtwork(item: item, size: 54)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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

                if let count, count > 0 {
                    Text("×\(count)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x0A1A33))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(LumiColor.blueChip))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .offset(x: -4, y: 4)
                }

                if equipped {
                    ZStack {
                        Circle().fill(LumiColor.yellow)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color(hex: 0x3A2400))
                    }
                    .frame(width: 18, height: 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .offset(x: -4, y: -4)
                }
            }

            Text(item.title)
                .font(.lumi(10.5, weight: .bold))
                .foregroundStyle(LumiColor.textBright)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 26, alignment: .top)

            statusLine
        }
    }

    @ViewBuilder private var statusLine: some View {
        if equipped {
            Text("Надет").font(.lumi(10, weight: .heavy)).foregroundStyle(LumiColor.yellow)
        } else if owned {
            Text(item.skinAssetName != nil ? "Куплен" : "Открыта")
                .font(.lumi(10, weight: .heavy))
                .foregroundStyle(LumiColor.green)
        } else if case .lessonsCompleted(let required) = item.unlock {
            Text("\(progress?.completedLessonIDs.count ?? 0)/\(required) уроков")
                .font(.lumi(9, weight: .bold))
                .foregroundStyle(LumiColor.textDim)
        } else if let price = item.priceInLumens {
            HStack(spacing: 3) {
                LumiIcon(name: "icon-lumen", size: 9, fallbackSystemImage: "star.fill")
                Text("\(price)")
            }
            .font(.lumi(11, weight: .heavy))
            .foregroundStyle(ShopService.canPurchase(item, progress: progress) ? LumiColor.yellow : LumiColor.textDim)
        }
    }
}

// MARK: - Item sheet

private struct ShopItemSheet: View {
    let item: ShopItem
    let progress: UserProgress?
    let onBuy: () -> Void
    let onToggleEquip: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var owned: Bool { ShopService.isOwned(item, progress: progress) }
    private var equipped: Bool { ShopService.isEquipped(item, progress: progress) }
    private var block: ShopService.PurchaseBlock? { ShopService.purchaseBlock(for: item, progress: progress) }

    var body: some View {
        ZStack {
            LumiBackground()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 38, height: 4)
                    .padding(.top, 10)

                ShopItemArtwork(item: item, size: 128)
                    .padding(.top, 4)

                VStack(spacing: 6) {
                    Text(item.title)
                        .font(.lumiScreenTitle(20))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)

                    if let rarity = item.rarity {
                        Text(rarity.rawValue)
                            .font(.lumi(11, weight: .heavy))
                            .foregroundStyle(Color(hex: 0x0A1A33))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(ShopStyle.rarityColor(rarity)))
                    }
                }

                Text(item.summary)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                if let count = ShopService.ownedCount(item, progress: progress) {
                    HStack(spacing: 6) {
                        Text("У тебя сейчас:")
                            .foregroundStyle(LumiColor.textSecondary)
                        Text("\(count)")
                            .foregroundStyle(Color.white)
                        if let limit = ShopService.storageLimit(for: item) {
                            Text("из \(limit)").foregroundStyle(LumiColor.textDim)
                        }
                    }
                    .font(.lumi(12, weight: .bold))
                }

                Spacer(minLength: 0)

                actionArea
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder private var actionArea: some View {
        VStack(spacing: 10) {
            if owned, item.skinAssetName != nil {
                PrimaryButton(title: equipped ? "Снять образ" : "Надеть образ", action: onToggleEquip)
            } else if owned {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Уже открыто — ищи в инвентаре")
                }
                .font(.lumi(13, weight: .bold))
                .foregroundStyle(LumiColor.green)
                .padding(.vertical, 12)
            } else if let block {
                VStack(spacing: 8) {
                    PrimaryButton(title: priceTitle, isEnabled: false, action: {})
                    Text(block.message)
                        .font(.lumi(11.5, weight: .semibold))
                        .foregroundStyle(block == .alreadyOwned ? LumiColor.textSecondary : LumiColor.orange1)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                PrimaryButton(title: priceTitle, action: onBuy)
            }

            TextLinkButton(title: "Закрыть") { dismiss() }
        }
    }

    private var priceTitle: String {
        guard let price = item.priceInLumens else { return "Недоступно" }
        return "Купить за \(price) ✦"
    }
}

#Preview {
    NavigationStack { ShopView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
