import Foundation
import Testing
@testable import LumiApp

/// До появления этого журнала +15 люменов давались за каждый заход в
/// практику, и валюту можно было фармить бесконечно. Тесты фиксируют новое
/// правило: одна награда в день на практику, сверх неё — только за
/// купленный бустер «Доп. задание дня».
struct PracticeRewardLedgerTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func day(_ offset: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .init(timeIntervalSince1970: 0)))!
    }

    @Test func firstSessionOfTheDayIsRewarded() {
        let calendar = utcCalendar
        let progress = UserProgress(lumens: 0)

        let outcome = PracticeRewardLedger.grantReward(
            for: .breathing, progress: progress, on: day(0, calendar: calendar), calendar: calendar
        )

        #expect(outcome == .rewarded(lumens: GamificationRules.lumensPerModeSession))
        #expect(progress.lumens == GamificationRules.lumensPerModeSession)
    }

    @Test func secondSessionSameDayGivesNothingWithoutABooster() {
        let calendar = utcCalendar
        let progress = UserProgress(lumens: 0)
        let today = day(0, calendar: calendar)

        PracticeRewardLedger.grantReward(for: .breathing, progress: progress, on: today, calendar: calendar)
        let second = PracticeRewardLedger.grantReward(for: .breathing, progress: progress, on: today, calendar: calendar)

        #expect(second == .alreadyRewardedToday)
        #expect(progress.lumens == GamificationRules.lumensPerModeSession, "фарм повторными заходами закрыт")
    }

    @Test func eachPracticeHasItsOwnDailyReward() {
        let calendar = utcCalendar
        let progress = UserProgress(lumens: 0)
        let today = day(0, calendar: calendar)

        for practice in Practice.allCases {
            let outcome = PracticeRewardLedger.grantReward(
                for: practice, progress: progress, on: today, calendar: calendar
            )
            #expect(outcome == .rewarded(lumens: GamificationRules.lumensPerModeSession))
        }

        #expect(progress.lumens == GamificationRules.lumensPerModeSession * Practice.allCases.count)
    }

    @Test func rewardComesBackTheNextDay() {
        let calendar = utcCalendar
        let progress = UserProgress(lumens: 0)

        PracticeRewardLedger.grantReward(for: .meditation, progress: progress, on: day(0, calendar: calendar), calendar: calendar)
        let tomorrow = PracticeRewardLedger.grantReward(
            for: .meditation, progress: progress, on: day(1, calendar: calendar), calendar: calendar
        )

        #expect(tomorrow == .rewarded(lumens: GamificationRules.lumensPerModeSession))
        #expect(progress.lumens == GamificationRules.lumensPerModeSession * 2)
    }

    @Test func extraTaskTokenBuysOneMoreRewardedSession() {
        let calendar = utcCalendar
        let progress = UserProgress(lumens: 0, extraDailyTaskTokens: 1)
        let today = day(0, calendar: calendar)

        PracticeRewardLedger.grantReward(for: .affirmations, progress: progress, on: today, calendar: calendar)
        let extra = PracticeRewardLedger.grantReward(for: .affirmations, progress: progress, on: today, calendar: calendar)
        let afterTokens = PracticeRewardLedger.grantReward(for: .affirmations, progress: progress, on: today, calendar: calendar)

        #expect(extra == .rewardedWithExtraTask(lumens: GamificationRules.lumensPerModeSession, tokensLeft: 0))
        #expect(afterTokens == .alreadyRewardedToday)
        #expect(progress.extraDailyTaskTokens == 0)
        #expect(progress.lumens == GamificationRules.lumensPerModeSession * 2)
    }

    @Test func previewMatchesWhatGrantWillDo() {
        let calendar = utcCalendar
        let progress = UserProgress(lumens: 0)
        let today = day(0, calendar: calendar)

        #expect(
            PracticeRewardLedger.preview(.breathing, progress: progress, on: today, calendar: calendar)
                == .rewarded(lumens: GamificationRules.lumensPerModeSession)
        )

        PracticeRewardLedger.grantReward(for: .breathing, progress: progress, on: today, calendar: calendar)

        #expect(
            PracticeRewardLedger.preview(.breathing, progress: progress, on: today, calendar: calendar)
                == .alreadyRewardedToday
        )
    }
}
