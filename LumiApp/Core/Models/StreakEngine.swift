import Foundation

/// Streak bookkeeping, split out of UserProgress so the day-diff/freeze
/// logic (previously entirely unimplemented — currentStreakDays was a
/// stored counter nothing ever mutated) is pure and testable.
///
/// Rules (Lumi_Gamification_Economy.docx, "Non-punitive streak"):
/// - 1 free freeze granted right after onboarding.
/// - 1 freeze accrues automatically every 7 days, regardless of activity.
/// - Max 2 freezes stored at once.
/// - A "Заморозка серии" freeze protects the streak across a missed day —
///   consumed automatically, not something the user manually triggers.
enum StreakEngine {
    /// Call when a lesson is completed. Advances or resets the streak
    /// based on how many calendar days elapsed since `lastActiveDate`,
    /// consuming stored freezes to bridge missed days where possible.
    static func recordLessonCompletion(
        on progress: UserProgress,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        let today = calendar.startOfDay(for: now)

        defer {
            if !progress.lessonCompletionDates.contains(where: { calendar.isDate($0, inSameDayAs: today) }) {
                progress.lessonCompletionDates.append(today)
            }
            progress.lastActiveDate = today
            progress.bestStreakDays = max(progress.bestStreakDays, progress.currentStreakDays)
        }

        guard let lastActive = progress.lastActiveDate else {
            progress.currentStreakDays = 1
            return
        }
        let lastActiveDay = calendar.startOfDay(for: lastActive)
        let missedDays = calendar.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0

        // Перерыв в два дня и больше, после которого человек всё-таки
        // вернулся — это то, что стоит отметить (достижение «Вернулся(ась)»).
        if missedDays >= 2 {
            progress.comebackCount += 1
        }

        switch missedDays {
        case ..<0:
            break // clock went backwards; leave streak untouched
        case 0:
            break // already active today, no change
        case 1:
            progress.currentStreakDays += 1
        default:
            let gapDays = missedDays - 1 // days strictly between last active and today
            if progress.streakFreezesAvailable >= gapDays {
                progress.streakFreezesAvailable -= gapDays
                for offset in 1...gapDays {
                    if let frozenDay = calendar.date(byAdding: .day, value: offset, to: lastActiveDay) {
                        progress.freezeUsedDates.append(frozenDay)
                    }
                }
                progress.currentStreakDays += 1
            } else {
                progress.currentStreakDays = 1
            }
        }
    }

    /// Почему ручную заморозку вообще нельзя было применить: движок тратит
    /// заморозки сам, задним числом, когда пропуск уже случился. Это
    /// правильно для «не наказывающей» механики, но не покрывает случай
    /// «я знаю заранее, что завтра не смогу» — а именно за этим её и
    /// покупают.
    enum ManualFreezeResult: Equatable {
        case applied(day: Date)
        /// Сегодня уже был урок — заморозка не нужна, тратить не даём.
        case notNeededToday
        /// День уже защищён заморозкой.
        case alreadyFrozen
        case noFreezesLeft
    }

    /// Защищает конкретный день (по умолчанию сегодняшний) вручную:
    /// списывает одну заморозку, отмечает день как закрытый и продолжает
    /// серию, будто занятие было.
    ///
    /// Намеренно не даёт потратить заморозку впустую: если день уже закрыт
    /// уроком или заморозкой, ничего не списывается.
    @discardableResult
    static func applyManualFreeze(
        on progress: UserProgress,
        for date: Date = .now,
        calendar: Calendar = .current
    ) -> ManualFreezeResult {
        let day = calendar.startOfDay(for: date)

        if progress.lessonCompletionDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
            return .notNeededToday
        }
        if progress.freezeUsedDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
            return .alreadyFrozen
        }
        guard progress.streakFreezesAvailable > 0 else {
            return .noFreezesLeft
        }

        progress.streakFreezesAvailable -= 1
        progress.freezeUsedDates.append(day)

        // Серия продолжается: замороженный день считается «пришёл».
        if let lastActive = progress.lastActiveDate {
            let lastActiveDay = calendar.startOfDay(for: lastActive)
            let gap = calendar.dateComponents([.day], from: lastActiveDay, to: day).day ?? 0
            if gap >= 1 {
                progress.currentStreakDays += 1
            }
        } else {
            progress.currentStreakDays = max(progress.currentStreakDays, 1)
        }

        if day >= calendar.startOfDay(for: progress.lastActiveDate ?? day) {
            progress.lastActiveDate = day
        }
        progress.bestStreakDays = max(progress.bestStreakDays, progress.currentStreakDays)

        return .applied(day: day)
    }

    /// Нужна ли пользователю кнопка «заморозить день» прямо сейчас:
    /// сегодня ещё не было урока и день не защищён.
    static func canApplyManualFreeze(
        on progress: UserProgress,
        for date: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        let day = calendar.startOfDay(for: date)
        guard progress.streakFreezesAvailable > 0 else { return false }
        if progress.lessonCompletionDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) { return false }
        if progress.freezeUsedDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) { return false }
        return true
    }

    /// Call on app launch (or whenever it's convenient) to grant the
    /// automatic every-7-days freeze. Safe to call often — it only grants
    /// once per elapsed 7-day window and never exceeds the storage cap.
    static func applyAutomaticFreezeIfDue(
        on progress: UserProgress,
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        guard progress.streakFreezesAvailable < GamificationRules.maxStoredStreakFreezes else { return }
        guard let reference = progress.lastAutomaticFreezeDate ?? progress.lastActiveDate else {
            progress.lastAutomaticFreezeDate = now
            return
        }
        let daysSince = calendar.dateComponents([.day], from: reference, to: now).day ?? 0
        guard daysSince >= GamificationRules.automaticFreezeIntervalDays else { return }

        let grants = daysSince / GamificationRules.automaticFreezeIntervalDays
        progress.streakFreezesAvailable = min(
            progress.streakFreezesAvailable + grants,
            GamificationRules.maxStoredStreakFreezes
        )
        progress.lastAutomaticFreezeDate = calendar.date(
            byAdding: .day,
            value: grants * GamificationRules.automaticFreezeIntervalDays,
            to: reference
        )
    }
}
