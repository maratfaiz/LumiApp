import Foundation

/// F13 — вся логика магазина: можно ли купить, что происходит после покупки,
/// что сейчас надето. Живёт отдельно от экрана, чтобы поведение можно было
/// покрыть тестами (`ShopServiceTests`), а не проверять руками в симуляторе.
///
/// Правило экономики (Lumi_Gamification_Economy.docx): люмены тратятся
/// только здесь, и ни одна покупка не может уйти «в никуда» — если предмет
/// уже есть или его негде хранить, покупка блокируется до нажатия.
enum ShopService {

    /// Почему предмет нельзя купить прямо сейчас.
    enum PurchaseBlock: Equatable {
        case alreadyOwned
        case notEnoughLumens(missing: Int)
        case storageFull(limit: Int)
        case notForSale(lessonsRequired: Int, lessonsCompleted: Int)

        var message: String {
            switch self {
            case .alreadyOwned:
                return "Уже куплено"
            case .notEnoughLumens(let missing):
                return "Не хватает \(missing) " + RussianPlural.form(missing, one: "люмена", few: "люменов", many: "люменов")
            case .storageFull(let limit):
                return "Больше \(limit) хранить нельзя — сначала израсходуй"
            case .notForSale(let required, let completed):
                return "Откроется после \(RussianPlural.lessons(required)) — пройдено \(completed)"
            }
        }
    }

    enum PurchaseResult: Equatable {
        case purchased(spent: Int)
        case blocked(PurchaseBlock)
    }

    // MARK: - Состояние

    static func isOwned(_ item: ShopItem, progress: UserProgress?) -> Bool {
        guard let progress else { return false }
        switch item.category {
        case .accessories, .featured:
            if case .lessonsCompleted(let required) = item.unlock {
                return progress.completedLessonIDs.count >= required
                    || progress.unlockedMascotSkinIDs.contains(item.id)
            }
            if item.skinAssetName != nil {
                return progress.unlockedMascotSkinIDs.contains(item.id)
            }
            return progress.unlockedSecretTechniqueIDs.contains(item.id)
        case .secretTechniques:
            return progress.unlockedSecretTechniqueIDs.contains(item.id)
        case .boosters:
            // Бустеры расходуются, поэтому «купленными» не становятся —
            // вместо этого показываем остаток (`ownedCount`).
            return false
        }
    }

    /// Сколько штук этого расходуемого предмета сейчас на руках.
    static func ownedCount(_ item: ShopItem, progress: UserProgress?) -> Int? {
        guard let progress else { return nil }
        switch item.id {
        case ShopCatalog.streakFreezeID: return progress.streakFreezesAvailable
        case ShopCatalog.extraTaskID: return progress.extraDailyTaskTokens
        case ShopCatalog.lessonHintID: return progress.lessonHintTokens
        default: return nil
        }
    }

    /// Потолок хранения для расходуемых предметов (nil — без потолка).
    static func storageLimit(for item: ShopItem) -> Int? {
        item.id == ShopCatalog.streakFreezeID ? GamificationRules.maxStoredStreakFreezes : nil
    }

    /// `nil` — покупка доступна; иначе причина блокировки.
    static func purchaseBlock(for item: ShopItem, progress: UserProgress?) -> PurchaseBlock? {
        if isOwned(item, progress: progress) { return .alreadyOwned }

        switch item.unlock {
        case .lessonsCompleted(let required):
            return .notForSale(
                lessonsRequired: required,
                lessonsCompleted: progress?.completedLessonIDs.count ?? 0
            )
        case .lumens(let price):
            if let limit = storageLimit(for: item),
               let owned = ownedCount(item, progress: progress),
               owned >= limit {
                return .storageFull(limit: limit)
            }
            let balance = progress?.lumens ?? 0
            if balance < price {
                return .notEnoughLumens(missing: price - balance)
            }
            return nil
        }
    }

    static func canPurchase(_ item: ShopItem, progress: UserProgress?) -> Bool {
        purchaseBlock(for: item, progress: progress) == nil
    }

    // MARK: - Покупка

    /// Списывает люмены и выдаёт предмет. Ничего не меняет, если покупка
    /// заблокирована — проверка и списание в одном месте, чтобы UI не мог
    /// разойтись с моделью.
    @discardableResult
    static func purchase(_ item: ShopItem, progress: UserProgress) -> PurchaseResult {
        if let block = purchaseBlock(for: item, progress: progress) {
            return .blocked(block)
        }
        guard case .lumens(let price) = item.unlock else {
            return .blocked(.alreadyOwned)
        }

        progress.lumens -= price

        switch item.id {
        case ShopCatalog.streakFreezeID:
            progress.streakFreezesAvailable = min(
                progress.streakFreezesAvailable + 1,
                GamificationRules.maxStoredStreakFreezes
            )
        case ShopCatalog.extraTaskID:
            progress.extraDailyTaskTokens += 1
        case ShopCatalog.lessonHintID:
            progress.lessonHintTokens += 1
        default:
            switch item.category {
            case .accessories, .featured:
                if item.skinAssetName != nil {
                    progress.unlockedMascotSkinIDs.append(item.id)
                } else {
                    progress.unlockedSecretTechniqueIDs.append(item.id)
                }
            case .secretTechniques:
                progress.unlockedSecretTechniqueIDs.append(item.id)
            case .boosters:
                break
            }
        }

        return .purchased(spent: price)
    }

    // MARK: - Образы

    static func isEquipped(_ item: ShopItem, progress: UserProgress?) -> Bool {
        progress?.equippedMascotSkinID == item.id
    }

    /// Надевает образ; повторный вызов на уже надетом — снимает его.
    static func toggleEquip(_ item: ShopItem, progress: UserProgress) {
        guard item.skinAssetName != nil, isOwned(item, progress: progress) else { return }
        progress.equippedMascotSkinID = (progress.equippedMascotSkinID == item.id) ? nil : item.id
    }

    // MARK: - Подсказка в уроке

    /// Подсказку уже открыли для этого урока — второй раз не списываем.
    static func isHintRevealed(lessonID: String, progress: UserProgress?) -> Bool {
        progress?.hintedLessonIDs.contains(lessonID) ?? false
    }

    /// Тратит один токен подсказки. `false`, если токенов нет.
    @discardableResult
    static func revealHint(lessonID: String, progress: UserProgress) -> Bool {
        if progress.hintedLessonIDs.contains(lessonID) { return true }
        guard progress.lessonHintTokens > 0 else { return false }
        progress.lessonHintTokens -= 1
        progress.hintedLessonIDs.append(lessonID)
        return true
    }
}
