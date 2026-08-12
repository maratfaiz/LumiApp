import Foundation
import Testing
@testable import LumiApp

/// Экономика магазина проверяется здесь, а не руками в симуляторе: покупка
/// должна списывать ровно цену, выдавать ровно один предмет и блокироваться
/// в понятных случаях.
struct ShopServiceTests {
    private func skin(_ id: String = "skin-classic") -> ShopItem {
        ShopCatalog.accessories.first { $0.id == id }!
    }

    private var freeze: ShopItem { ShopCatalog.boosters.first { $0.id == ShopCatalog.streakFreezeID }! }
    private var hint: ShopItem { ShopCatalog.boosters.first { $0.id == ShopCatalog.lessonHintID }! }
    private var technique: ShopItem { ShopCatalog.secretTechniques.first! }

    @Test func purchaseSpendsExactlyThePrice() {
        let progress = UserProgress(lumens: 100, streakFreezesAvailable: 0)
        let item = skin()

        let result = ShopService.purchase(item, progress: progress)

        #expect(result == .purchased(spent: 80))
        #expect(progress.lumens == 20)
        #expect(progress.unlockedMascotSkinIDs == ["skin-classic"])
    }

    @Test func purchaseBlockedWithoutEnoughLumens() {
        let progress = UserProgress(lumens: 10, streakFreezesAvailable: 0)

        let result = ShopService.purchase(skin(), progress: progress)

        #expect(result == .blocked(.notEnoughLumens(missing: 70)))
        #expect(progress.lumens == 10, "неудачная покупка не должна трогать баланс")
        #expect(progress.unlockedMascotSkinIDs.isEmpty)
    }

    @Test func cannotBuyTheSameSkinTwice() {
        let progress = UserProgress(lumens: 500, streakFreezesAvailable: 0)
        ShopService.purchase(skin(), progress: progress)

        let second = ShopService.purchase(skin(), progress: progress)

        #expect(second == .blocked(.alreadyOwned))
        #expect(progress.lumens == 420)
        #expect(progress.unlockedMascotSkinIDs.count == 1)
    }

    @Test func epicSkinsCannotBeBoughtForLumens() {
        let progress = UserProgress(lumens: 10_000, streakFreezesAvailable: 0)
        let epic = skin("skin-cosmonaut")

        let result = ShopService.purchase(epic, progress: progress)

        #expect(result == .blocked(.notForSale(lessonsRequired: 20, lessonsCompleted: 0)))
        #expect(progress.lumens == 10_000)
    }

    @Test func epicSkinIsOwnedOnceEnoughLessonsAreDone() {
        let progress = UserProgress(
            lumens: 0,
            streakFreezesAvailable: 0,
            completedLessonIDs: (1...20).map { "lesson-\($0)" }
        )

        #expect(ShopService.isOwned(skin("skin-cosmonaut"), progress: progress))
    }

    @Test func freezePurchaseIsBlockedAtTheStorageCap() {
        let progress = UserProgress(lumens: 500, streakFreezesAvailable: GamificationRules.maxStoredStreakFreezes)

        let result = ShopService.purchase(freeze, progress: progress)

        #expect(result == .blocked(.storageFull(limit: GamificationRules.maxStoredStreakFreezes)))
        #expect(progress.lumens == 500, "люмены не должны сгорать впустую")
    }

    @Test func freezePurchaseAddsOneFreeze() {
        let progress = UserProgress(lumens: 500, streakFreezesAvailable: 0)

        ShopService.purchase(freeze, progress: progress)

        #expect(progress.streakFreezesAvailable == 1)
        #expect(progress.lumens == 500 - GamificationRules.streakFreezePriceLumens)
    }

    @Test func boostersStayBuyableBecauseTheyAreConsumable() {
        let progress = UserProgress(lumens: 500, streakFreezesAvailable: 0)

        ShopService.purchase(hint, progress: progress)
        ShopService.purchase(hint, progress: progress)

        #expect(progress.lessonHintTokens == 2)
        #expect(ShopService.isOwned(hint, progress: progress) == false)
    }

    @Test func techniquePurchaseUnlocksIt() {
        let progress = UserProgress(lumens: 100, streakFreezesAvailable: 0)

        ShopService.purchase(technique, progress: progress)

        #expect(ShopService.isOwned(technique, progress: progress))
        #expect(progress.unlockedSecretTechniqueIDs == [technique.id])
    }

    @Test func equipTogglesOnAndOff() {
        let progress = UserProgress(lumens: 500, streakFreezesAvailable: 0)
        let item = skin()
        ShopService.purchase(item, progress: progress)

        ShopService.toggleEquip(item, progress: progress)
        #expect(progress.equippedMascotSkinID == "skin-classic")

        ShopService.toggleEquip(item, progress: progress)
        #expect(progress.equippedMascotSkinID == nil)
    }

    @Test func cannotEquipSomethingNotOwned() {
        let progress = UserProgress(lumens: 0, streakFreezesAvailable: 0)

        ShopService.toggleEquip(skin(), progress: progress)

        #expect(progress.equippedMascotSkinID == nil)
    }

    @Test func hintSpendsOneTokenAndStaysRevealed() {
        let progress = UserProgress(lumens: 0, streakFreezesAvailable: 0, lessonHintTokens: 1)

        #expect(ShopService.revealHint(lessonID: "lesson-1", progress: progress))
        #expect(progress.lessonHintTokens == 0)

        // Повторный вход в тот же урок — бесплатно.
        #expect(ShopService.revealHint(lessonID: "lesson-1", progress: progress))
        #expect(progress.lessonHintTokens == 0)

        // А другой урок уже не открыть.
        #expect(ShopService.revealHint(lessonID: "lesson-2", progress: progress) == false)
        #expect(ShopService.isHintRevealed(lessonID: "lesson-2", progress: progress) == false)
    }
}
