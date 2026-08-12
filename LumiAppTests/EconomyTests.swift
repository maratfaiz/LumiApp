import Foundation
import Testing
@testable import LumiApp

/// Уровни, достижения и ручная заморозка выдают настоящие награды —
/// значит, ошибка здесь стоит пользователю люменов. Поэтому тесты.
struct LevelSystemTests {
    @Test func levelRewardIsGrantedOnceAndOnlyOnce() {
        let progress = UserProgress(xp: 30, lumens: 0, streakFreezesAvailable: 0)

        let first = LevelSystem.claimPendingRewards(for: progress)
        let second = LevelSystem.claimPendingRewards(for: progress)

        #expect(first.map(\.level) == [2])
        #expect(second.isEmpty, "повторный вызов не должен ничего начислять")
        #expect(progress.lumens == 25)
    }

    @Test func skippingSeveralLevelsAtOnceGrantsAllOfThem() {
        // 180 XP — это пятый уровень: награды за 2, 3, 4 и 5 разом.
        let progress = UserProgress(xp: 180, lumens: 0, streakFreezesAvailable: 0)

        let rewards = LevelSystem.claimPendingRewards(for: progress)

        #expect(rewards.map(\.level) == [2, 3, 4, 5])
        #expect(progress.lumens == 25 + 25 + 30 + 40)
        #expect(progress.streakFreezesAvailable == 1, "уровень 3 даёт заморозку")
        #expect(progress.lessonHintTokens == 1, "уровень 4 даёт подсказку")
        #expect(progress.unlockedMascotSkinIDs.contains("skin-classic"), "уровень 5 дарит образ")
    }

    @Test func everyLevelHasATitle() {
        for reward in LevelSystem.rewards {
            #expect(!reward.title.isEmpty)
            #expect(!reward.rewardLines.isEmpty, "уровень без награды не имеет смысла")
        }
    }
}

struct AchievementServiceTests {
    @Test func achievementPaysOutOnceAndCountsTowardBalance() {
        let progress = UserProgress(lumens: 0, streakFreezesAvailable: 0, completedLessonIDs: ["lesson-1"])

        let first = AchievementService.claimUnlocked(for: progress)
        let second = AchievementService.claimUnlocked(for: progress)

        #expect(first.contains { $0.id == "achievement-first-lesson" })
        #expect(second.isEmpty)
        #expect(progress.lumens == 20)
    }

    @Test func streakAchievementAlsoGivesAFreeze() {
        let progress = UserProgress(lumens: 0, bestStreakDays: 7, streakFreezesAvailable: 0)

        AchievementService.claimUnlocked(for: progress)

        // 3 дня (20) + 7 дней (30) — обе серии открыты одним значением.
        #expect(progress.lumens == 50)
        #expect(progress.streakFreezesAvailable == 1)
    }

    @Test func noAchievementRewardsNothing() {
        for achievement in AchievementCatalog.all {
            let total = achievement.rewardLumens + achievement.rewardFreezes + achievement.rewardHints
            #expect(total > 0, "достижение «\(achievement.title)» ничего не даёт")
        }
    }

    @Test func progressIsClampedToOne() {
        let progress = UserProgress(lumens: 0, bestStreakDays: 100, streakFreezesAvailable: 0)
        for achievement in AchievementCatalog.all {
            let value = achievement.progress(progress)
            #expect(value >= 0 && value <= 1)
        }
    }
}

struct ManualFreezeTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func day(_ offset: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .init(timeIntervalSince1970: 0)))!
    }

    @Test func manualFreezeProtectsTheDayAndContinuesTheStreak() {
        let calendar = utcCalendar
        let progress = UserProgress(currentStreakDays: 3, streakFreezesAvailable: 1, lastActiveDate: day(0, calendar: calendar))

        let result = StreakEngine.applyManualFreeze(on: progress, for: day(1, calendar: calendar), calendar: calendar)

        #expect(result == .applied(day: day(1, calendar: calendar)))
        #expect(progress.streakFreezesAvailable == 0)
        #expect(progress.currentStreakDays == 4)
        #expect(progress.freezeUsedDates.count == 1)
    }

    @Test func manualFreezeIsRefusedWhenTheDayIsAlreadyDone() {
        let calendar = utcCalendar
        let today = day(0, calendar: calendar)
        let progress = UserProgress(streakFreezesAvailable: 1, lessonCompletionDates: [today], lastActiveDate: today)

        let result = StreakEngine.applyManualFreeze(on: progress, for: today, calendar: calendar)

        #expect(result == .notNeededToday)
        #expect(progress.streakFreezesAvailable == 1, "заморозка не должна сгорать впустую")
    }

    @Test func manualFreezeIsRefusedTwiceOnTheSameDay() {
        let calendar = utcCalendar
        let today = day(0, calendar: calendar)
        let progress = UserProgress(streakFreezesAvailable: 2, lastActiveDate: day(-1, calendar: calendar))

        StreakEngine.applyManualFreeze(on: progress, for: today, calendar: calendar)
        let second = StreakEngine.applyManualFreeze(on: progress, for: today, calendar: calendar)

        #expect(second == .alreadyFrozen)
        #expect(progress.streakFreezesAvailable == 1)
    }

    @Test func manualFreezeNeedsAFreeze() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 0)

        #expect(StreakEngine.applyManualFreeze(on: progress, for: day(0, calendar: calendar), calendar: calendar) == .noFreezesLeft)
        #expect(StreakEngine.canApplyManualFreeze(on: progress, for: day(0, calendar: calendar), calendar: calendar) == false)
    }

    @Test func returningAfterABreakCountsAsAComeback() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 0, lastActiveDate: day(0, calendar: calendar))

        StreakEngine.recordLessonCompletion(on: progress, now: day(4, calendar: calendar), calendar: calendar)

        #expect(progress.comebackCount == 1)
    }
}

/// Баланс — тоже поведение: если урок вдруг станет приносить меньше
/// практики, приложение начнёт поощрять не то, ради чего сделано.
struct EconomyBalanceTests {
    @Test func lessonPaysMoreThanAPractice() {
        #expect(GamificationRules.lumensPerLesson > GamificationRules.lumensPerModeSession)
    }

    @Test func dailyPracticeIncomeStaysBelowLessonPlusPractices() {
        let maxPracticeIncome = GamificationRules.lumensPerModeSession * GamificationRules.maxRewardedPracticesPerDay
        // Практики не должны в одиночку перекрывать самый дорогой образ
        // быстрее, чем за неделю — иначе гардероб теряет смысл.
        #expect(maxPracticeIncome * 7 < GamificationRules.accessoryPriceRange.upperBound * 2)
    }

    @Test func everyPurchasableItemIsReachableInAReasonableTime() {
        let dailyIncome = GamificationRules.lumensPerLesson
            + GamificationRules.lumensPerModeSession * GamificationRules.maxRewardedPracticesPerDay
        let priciest = ShopCatalog.all.compactMap(\.priceInLumens).max() ?? 0
        let days = Double(priciest) / Double(dailyIncome)
        #expect(days <= 10, "самый дорогой предмет должен быть достижим примерно за неделю активности")
    }
}
