import Foundation

/// F13 (rewritten per Lumi_Functional_Requirements.docx v2.0): 4 categories.
/// Level/XP is a profile status indicator only — it never gates a shop
/// unlock (this overrides an earlier, since-reversed design).
enum ShopCategory: String, CaseIterable, Identifiable {
    case featured = "Популярное"
    case accessories = "Аксессуары"
    case secretTechniques = "Секретные техники"
    case boosters = "Бустеры"

    var id: String { rawValue }
}

enum AccessoryRarity: String, Codable {
    case common = "Обычный"
    case rare = "Редкий"
    case epic = "Эпический"
}

/// How an item is unlocked. Accessories are lumens OR lessons-completed,
/// never both; everything else is lumens.
enum ShopItemUnlock: Hashable {
    case lumens(Int)
    case lessonsCompleted(Int)
}

struct ShopItem: Identifiable, Hashable {
    let id: String
    let title: String
    let category: ShopCategory
    let unlock: ShopItemUnlock
    /// Only set for accessories that map to real mascot skin art
    /// (docs/design/prototype/assets/skin-*.png).
    let skinAssetName: String?
    let rarity: AccessoryRarity?

    init(id: String, title: String, category: ShopCategory, unlock: ShopItemUnlock, skinAssetName: String? = nil, rarity: AccessoryRarity? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.unlock = unlock
        self.skinAssetName = skinAssetName
        self.rarity = rarity
    }
}
