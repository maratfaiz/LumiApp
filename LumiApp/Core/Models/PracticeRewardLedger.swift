import Foundation

/// Практики из F26/F27/F29.
enum Practice: String, CaseIterable, Identifiable {
    case breathing
    case affirmations
    case meditation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breathing: return "Дыхание"
        case .affirmations: return "Аффирмации"
        case .meditation: return "Медитация"
        }
    }
}

/// Считает, положены ли за практику люмены прямо сейчас.
///
/// Два ограничения, оба ради баланса (см. `GamificationRules`):
/// 1. одна практика приносит люмены не чаще раза в день;
/// 2. всего в день не больше `maxRewardedPracticesPerDay` награждаемых
///    практик — иначе три практики в день приносили бы больше, чем уроки,
///    ради которых приложение и существует.
///
/// Купленный бустер «Доп. задание дня» разово снимает оба ограничения —
/// ради этого его и покупают. Практика без награды всё равно доступна и
/// засчитывается в счётчик практик: ограничение экономическое, а не
/// запрет заниматься.
enum PracticeRewardLedger {

    enum Outcome: Equatable {
        /// Обычная награда за день.
        case rewarded(lumens: Int)
        /// Награда сверх дневной — списан токен «Доп. задание дня».
        case rewardedWithExtraTask(lumens: Int, tokensLeft: Int)
        /// Эта практика сегодня уже приносила люмены.
        case alreadyRewardedToday
        /// Дневной лимит награждаемых практик исчерпан другими практиками.
        case dailyLimitReached(limit: Int)

        var isRewarded: Bool {
            switch self {
            case .rewarded, .rewardedWithExtraTask: return true
            case .alreadyRewardedToday, .dailyLimitReached: return false
            }
        }
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func baseKey(_ practice: Practice, on date: Date, calendar: Calendar = .current) -> String {
        "\(practice.rawValue)-\(dayKey(date, calendar: calendar))"
    }

    static func hasBaseReward(
        _ practice: Practice,
        progress: UserProgress,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        progress.rewardedPracticeKeys.contains(baseKey(practice, on: date, calendar: calendar))
    }

    /// Сколько наград уже выдано сегодня (по всем практикам, без учёта
    /// докупленных за токен — они лимит не занимают).
    static func rewardsGrantedToday(
        progress: UserProgress,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let day = dayKey(date, calendar: calendar)
        return progress.rewardedPracticeKeys.filter { $0.hasSuffix(day) }.count
    }

    /// Что пользователь получит, если завершит практику прямо сейчас —
    /// чтобы подпись на экране не обещала лишнего.
    static func preview(
        _ practice: Practice,
        progress: UserProgress?,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Outcome {
        guard let progress else {
            return .rewarded(lumens: GamificationRules.lumensPerModeSession)
        }
        return evaluate(practice, progress: progress, on: date, calendar: calendar).outcome
    }

    /// Начисляет награду за завершённую сессию, если она положена, и в любом
    /// случае увеличивает счётчик пройденных практик.
    @discardableResult
    static func grantReward(
        for practice: Practice,
        progress: UserProgress,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Outcome {
        progress.practiceSessionCount += 1

        let evaluation = evaluate(practice, progress: progress, on: date, calendar: calendar)
        let key = baseKey(practice, on: date, calendar: calendar)

        switch evaluation.kind {
        case .base:
            progress.rewardedPracticeKeys.append(key)
            progress.lumens += GamificationRules.lumensPerModeSession
        case .extraTask:
            progress.extraDailyTaskTokens -= 1
            let extraIndex = progress.rewardedPracticeKeys.filter { $0.hasPrefix("\(key)-extra") }.count + 1
            progress.rewardedPracticeKeys.append("\(key)-extra\(extraIndex)")
            progress.lumens += GamificationRules.lumensPerModeSession
        case .none:
            break
        }

        // Пересчитываем исход уже после списания токена, чтобы «осталось N»
        // показывало настоящий остаток.
        switch evaluation.kind {
        case .extraTask:
            return .rewardedWithExtraTask(
                lumens: GamificationRules.lumensPerModeSession,
                tokensLeft: progress.extraDailyTaskTokens
            )
        default:
            return evaluation.outcome
        }
    }

    // MARK: - Общая оценка

    private enum RewardKind { case base, extraTask, none }

    private struct Evaluation {
        let kind: RewardKind
        let outcome: Outcome
    }

    private static func evaluate(
        _ practice: Practice,
        progress: UserProgress,
        on date: Date,
        calendar: Calendar
    ) -> Evaluation {
        let alreadyForThisPractice = hasBaseReward(practice, progress: progress, on: date, calendar: calendar)
        let limit = GamificationRules.maxRewardedPracticesPerDay
        let usedToday = rewardsGrantedToday(progress: progress, on: date, calendar: calendar)

        if !alreadyForThisPractice && usedToday < limit {
            return Evaluation(kind: .base, outcome: .rewarded(lumens: GamificationRules.lumensPerModeSession))
        }

        if progress.extraDailyTaskTokens > 0 {
            return Evaluation(
                kind: .extraTask,
                outcome: .rewardedWithExtraTask(
                    lumens: GamificationRules.lumensPerModeSession,
                    tokensLeft: progress.extraDailyTaskTokens - 1
                )
            )
        }

        return Evaluation(
            kind: .none,
            outcome: alreadyForThisPractice ? .alreadyRewardedToday : .dailyLimitReached(limit: limit)
        )
    }
}
