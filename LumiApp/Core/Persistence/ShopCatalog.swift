import Foundation

/// F13 shop inventory. Common/rare accessories cost 80–200 lumens; the 3
/// named epic accessories unlock at 20/30/40 completed lessons instead —
/// intentionally not purchasable, so pay-to-win can't apply to them either.
/// "Подсказка в уроке" is a deliberate, documented exception to the
/// no-pay-to-win rule (Product Owner decision, not an oversight) — don't
/// "fix" it into a cosmetic-only item.
enum ShopCatalog {
    // Расходуемые бустеры разбираются по id и в ShopService, и в UI —
    // держим строки в одном месте.
    static let streakFreezeID = "booster-streak-freeze"
    static let extraTaskID = "booster-extra-task"
    static let lessonHintID = "booster-lesson-hint"

    static let selfEmbraceID = "technique-self-embrace"
    static let emotionDiaryID = "technique-emotion-diary"
    static let valuesFocusID = "technique-values-focus"

    static let accessories: [ShopItem] = [
        ShopItem(
            id: "skin-classic", title: "Классика",
            summary: "Базовый образ Луми — спокойный и нейтральный.",
            category: .accessories, unlock: .lumens(80),
            skinAssetName: "skin-classic", rarity: .common
        ),
        ShopItem(
            id: "skin-sport", title: "Спортивный костюм",
            summary: "Луми в спортивной форме — для дней, когда нужен заряд.",
            category: .accessories, unlock: .lumens(100),
            skinAssetName: "skin-sport", rarity: .common
        ),
        ShopItem(
            id: "skin-musician", title: "Музыкант",
            summary: "Луми с наушниками и гитарой.",
            category: .accessories, unlock: .lumens(120),
            skinAssetName: "skin-musician", rarity: .rare
        ),
        ShopItem(
            id: "skin-scientist", title: "Учёный",
            summary: "Луми в халате — для любопытных дней.",
            category: .accessories, unlock: .lumens(150),
            skinAssetName: "skin-scientist", rarity: .rare
        ),
        ShopItem(
            id: "skin-night", title: "Ночной образ",
            summary: "Луми в пижаме — подходит к вечерним практикам.",
            category: .accessories, unlock: .lumens(150),
            skinAssetName: "skin-night", rarity: .rare
        ),
        ShopItem(
            id: "skin-traveler", title: "Путешественник",
            summary: "Луми с рюкзаком — в пути к себе.",
            category: .accessories, unlock: .lumens(200),
            skinAssetName: "skin-traveler", rarity: .rare
        ),
        ShopItem(
            id: "skin-cosmonaut", title: "Костюм космонавта",
            summary: "Открывается за 20 пройденных уроков — купить нельзя.",
            category: .accessories, unlock: .lessonsCompleted(20),
            skinAssetName: "skin-cosmonaut", rarity: .epic
        ),
        ShopItem(
            id: "skin-wizard", title: "Мантия волшебника",
            summary: "Открывается за 30 пройденных уроков — купить нельзя.",
            category: .accessories, unlock: .lessonsCompleted(30),
            skinAssetName: "skin-wizard", rarity: .epic
        ),
        ShopItem(
            id: "skin-lucky", title: "Талисман удачи",
            summary: "Открывается за 40 пройденных уроков — купить нельзя.",
            category: .accessories, unlock: .lessonsCompleted(40),
            skinAssetName: "skin-lucky", rarity: .epic
        ),
    ]

    static let secretTechniques: [ShopItem] = [
        ShopItem(
            id: selfEmbraceID, title: "«Самообъятие»",
            summary: "Практика самосострадания на 1 минуту: обнять себя и побыть с тёплой фразой. Останется в приложении навсегда.",
            category: .secretTechniques, unlock: .lumens(GamificationRules.secretTechniquePriceLumens),
            iconAssetName: "item-selfhug"
        ),
        ShopItem(
            id: emotionDiaryID, title: "Дневник эмоций",
            summary: "Записывай, что чувствуешь и из-за чего. Записи сохраняются, их можно перечитать.",
            category: .secretTechniques, unlock: .lumens(GamificationRules.secretTechniquePriceLumens),
            iconAssetName: "item-journal"
        ),
        ShopItem(
            id: valuesFocusID, title: "Фокус на ценностях",
            summary: "Выбрать ценность и одно маленькое действие по ней на сегодня.",
            category: .secretTechniques, unlock: .lumens(GamificationRules.secretTechniquePriceLumens),
            iconAssetName: "item-target"
        ),
    ]

    static let boosters: [ShopItem] = [
        ShopItem(
            id: streakFreezeID, title: "Заморозка серии",
            summary: "Сохранит серию за пропущенный день — применяется сама. Хранить можно не больше \(GamificationRules.maxStoredStreakFreezes).",
            category: .boosters, unlock: .lumens(GamificationRules.streakFreezePriceLumens),
            iconAssetName: "item-freeze"
        ),
        ShopItem(
            id: extraTaskID, title: "Доп. задание дня",
            summary: "Ещё одна практика за люмены сверх дневной нормы. Списывается сама, когда завершаешь практику, за которую сегодня уже получал награду.",
            category: .boosters, unlock: .lumens(30),
            iconAssetName: "item-plus"
        ),
        ShopItem(
            id: lessonHintID, title: "Подсказка в уроке",
            summary: "Откроет пример ответа в упражнении. Один урок — один токен, открытая подсказка остаётся навсегда.",
            category: .boosters, unlock: .lumens(20),
            iconAssetName: "item-hint"
        ),
    ]

    static var all: [ShopItem] { accessories + secretTechniques + boosters }

    static func item(id: String) -> ShopItem? {
        all.first { $0.id == id }
    }

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
