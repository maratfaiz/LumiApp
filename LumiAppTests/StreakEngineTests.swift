import Foundation
import Testing
@testable import LumiApp

struct StreakEngineTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func day(_ offset: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .init(timeIntervalSince1970: 0)))!
    }

    @Test func firstCompletionStartsStreakAtOne() {
        let calendar = utcCalendar
        let progress = UserProgress()
        StreakEngine.recordLessonCompletion(on: progress, now: day(0, calendar: calendar), calendar: calendar)
        #expect(progress.currentStreakDays == 1)
        #expect(progress.bestStreakDays == 1)
        #expect(progress.lessonCompletionDates.count == 1)
    }

    @Test func sameDayCompletionDoesNotDuplicateOrInflate() {
        let calendar = utcCalendar
        let progress = UserProgress()
        let today = day(0, calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: today, calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: today, calendar: calendar)
        #expect(progress.currentStreakDays == 1)
        #expect(progress.lessonCompletionDates.count == 1)
    }

    @Test func consecutiveDayIncrementsStreak() {
        let calendar = utcCalendar
        let progress = UserProgress()
        StreakEngine.recordLessonCompletion(on: progress, now: day(0, calendar: calendar), calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: day(1, calendar: calendar), calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: day(2, calendar: calendar), calendar: calendar)
        #expect(progress.currentStreakDays == 3)
        #expect(progress.bestStreakDays == 3)
    }

    @Test func missedDayWithEnoughFreezesBridgesTheStreak() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 2)
        StreakEngine.recordLessonCompletion(on: progress, now: day(0, calendar: calendar), calendar: calendar)
        // Skip day 1 entirely, come back on day 2 — 1 day gap, needs 1 freeze.
        StreakEngine.recordLessonCompletion(on: progress, now: day(2, calendar: calendar), calendar: calendar)
        #expect(progress.currentStreakDays == 2)
        #expect(progress.streakFreezesAvailable == 1)
        #expect(progress.freezeUsedDates.count == 1)
    }

    @Test func missedDayWithoutEnoughFreezesResetsStreak() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 0)
        StreakEngine.recordLessonCompletion(on: progress, now: day(0, calendar: calendar), calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: day(5, calendar: calendar), calendar: calendar)
        #expect(progress.currentStreakDays == 1)
        #expect(progress.streakFreezesAvailable == 0)
        #expect(progress.bestStreakDays == 1)
    }

    @Test func bestStreakSurvivesAfterAReset() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 0)
        StreakEngine.recordLessonCompletion(on: progress, now: day(0, calendar: calendar), calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: day(1, calendar: calendar), calendar: calendar)
        StreakEngine.recordLessonCompletion(on: progress, now: day(2, calendar: calendar), calendar: calendar)
        // Big gap, no freezes — streak resets, but best should remember the 3.
        StreakEngine.recordLessonCompletion(on: progress, now: day(10, calendar: calendar), calendar: calendar)
        #expect(progress.currentStreakDays == 1)
        #expect(progress.bestStreakDays == 3)
    }

    @Test func automaticFreezeGrantedAfterSevenDays() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 0)
        progress.lastActiveDate = day(0, calendar: calendar)
        StreakEngine.applyAutomaticFreezeIfDue(on: progress, now: day(7, calendar: calendar), calendar: calendar)
        #expect(progress.streakFreezesAvailable == 1)
    }

    @Test func automaticFreezeNeverExceedsCap() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: GamificationRules.maxStoredStreakFreezes)
        progress.lastActiveDate = day(0, calendar: calendar)
        StreakEngine.applyAutomaticFreezeIfDue(on: progress, now: day(30, calendar: calendar), calendar: calendar)
        #expect(progress.streakFreezesAvailable == GamificationRules.maxStoredStreakFreezes)
    }

    @Test func automaticFreezeNotYetDueGrantsNothing() {
        let calendar = utcCalendar
        let progress = UserProgress(streakFreezesAvailable: 0)
        progress.lastActiveDate = day(0, calendar: calendar)
        StreakEngine.applyAutomaticFreezeIfDue(on: progress, now: day(3, calendar: calendar), calendar: calendar)
        #expect(progress.streakFreezesAvailable == 0)
    }
}
