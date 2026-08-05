import Foundation

/// F13 shop inventory. Common/rare accessories cost 80–200 lumens; the 3
/// named epic accessories unlock at 20/30/40 completed lessons instead —
/// intentionally not purchasable, so pay-to-win can't apply to them either.
/// "Подсказка в уроке" is a deliberate, documented exception to the
/// no-pay-to-win rule (Product Owner decision, not an oversight) — don't
/// "fix" it into a cosmetic-only item.
enum ShopCatalog {
    static let accessories: [ShopItem] = [
        ShopItem(id: "skin-classic", title: "Классика", category: .accessories, unlock: .lumens(80), skinAssetName: "skin-classic", rarity: .common),
        ShopItem(id: "skin-sport", title: "Спортивный костюм", category: .accessories, unlock: .lumens(100), skinAssetName: "skin-sport", rarity: .common),
        ShopItem(id: "skin-musician", title: "Музыкант", category: .accessories, unlock: .lumens(120), skinAssetName: "skin-musician", rarity: .rare),
        ShopItem(id: "skin-scientist", title: "Учёный", category: .accessories, unlock: .lumens(150), skinAssetName: "skin-scientist", rarity: .rare),
        ShopItem(id: "skin-night", title: "Ночной образ", category: .accessories, unlock: .lumens(150), skinAssetName: "skin-night", rarity: .rare),
        ShopItem(id: "skin-traveler", title: "Путешественник", category: .accessories, unlock: .lumens(200), skinAssetName: "skin-traveler", rarity: .rare),
        ShopItem(id: "skin-cosmonaut", title: "Костюм космонавта", category: .accessories, unlock: .lessonsCompleted(20), skinAssetName: "skin-cosmonaut", rarity: .epic),
        ShopItem(id: "skin-wizard", title: "Мантия волшебника", category: .accessories, unlock: .lessonsCompleted(30), skinAssetName: "skin-wizard", rarity: .epic),
        ShopItem(id: "skin-lucky", title: "Талисман удачи", category: .accessories, unlock: .lessonsCompleted(40), skinAssetName: "skin-lucky", rarity: .epic),
    ]

    static let secretTechniques: [ShopItem] = [
        ShopItem(id: "technique-self-embrace", title: "«Самообъятие»", category: .secretTechniques, unlock: .lumens(40)),
        ShopItem(id: "technique-emotion-diary", title: "Дневник эмоций", category: .secretTechniques, unlock: .lumens(40)),
        ShopItem(id: "technique-values-focus", title: "Фокус на ценностях", category: .secretTechniques, unlock: .lumens(40)),
    ]

    static let boosters: [ShopItem] = [
        ShopItem(id: "booster-streak-freeze", title: "Заморозка серии", category: .boosters, unlock: .lumens(GamificationRules.streakFreezePriceLumens)),
        ShopItem(id: "booster-extra-task", title: "Доп. задание дня", category: .boosters, unlock: .lumens(30)),
        ShopItem(id: "booster-lesson-hint", title: "Подсказка в уроке", category: .boosters, unlock: .lumens(20)),
    ]

    static var all: [ShopItem] { accessories + secretTechniques + boosters }

    /// "Популярное" tab: cheapest item per category, one each.
    static var featured: [ShopItem] {
        [accessories.first, secretTechniques.first, boosters.first].compactMap { $0 }
    }

    static func items(in category: ShopCategory) -> [ShopItem] {
        switch category {
        case .featured: return featured
        case .accessories: return accessories
        case .secretTechniques: return secretTechniques
        case .boosters: return boosters
        }
    }
}
