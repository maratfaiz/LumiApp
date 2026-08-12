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
/// Зачем: до этого награда выдавалась за каждую сессию, и +15 люменов можно
/// было фармить бесконечно, просто заходя в «Дыхание» и выходя — тогда
/// цены в магазине ничего не значат. Теперь каждая практика приносит
/// люмены **один раз в день**, а купленный бустер «Доп. задание дня»
/// разово снимает это ограничение — ради этого его и покупают.
enum PracticeRewardLedger {

    enum Outcome: Equatable {
        /// Обычная награда за день.
        case rewarded(lumens: Int)
        /// Награда сверх дневной — списан токен «Доп. задание дня».
        case rewardedWithExtraTask(lumens: Int, tokensLeft: Int)
        /// Сегодня уже получено, докупить нечем.
        case alreadyRewardedToday
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func baseKey(_ practice: Practice, on date: Date, calendar: Calendar = .current) -> String {
        "\(practice.rawValue)-\(dayKey(date, calendar: calendar))"
    }

    /// Была ли уже выдана обычная (не докупленная) награда за сегодня.
    static func hasBaseReward(
        _ practice: Practice,
        progress: UserProgress,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        progress.rewardedPracticeKeys.contains(baseKey(practice, on: date, calendar: calendar))
    }

    /// Что пользователь получит, если завершит практику прямо сейчас —
    /// для честной подписи на экране ещё до финиша.
    static func preview(
        _ practice: Practice,
        progress: UserProgress?,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Outcome {
        guard let progress else {
            return .rewarded(lumens: GamificationRules.lumensPerModeSession)
        }
        if !hasBaseReward(practice, progress: progress, on: date, calendar: calendar) {
            return .rewarded(lumens: GamificationRules.lumensPerModeSession)
        }
        if progress.extraDailyTaskTokens > 0 {
            return .rewardedWithExtraTask(
                lumens: GamificationRules.lumensPerModeSession,
                tokensLeft: progress.extraDailyTaskTokens - 1
            )
        }
        return .alreadyRewardedToday
    }

    /// Начисляет награду за завершённую сессию, если она положена.
    /// Возвращает то же, что показал `preview`, и уже применяет изменения.
    @discardableResult
    static func grantReward(
        for practice: Practice,
        progress: UserProgress,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Outcome {
        let key = baseKey(practice, on: date, calendar: calendar)

        if !progress.rewardedPracticeKeys.contains(key) {
            progress.rewardedPracticeKeys.append(key)
            progress.lumens += GamificationRules.lumensPerModeSession
            return .rewarded(lumens: GamificationRules.lumensPerModeSession)
        }

        guard progress.extraDailyTaskTokens > 0 else {
            return .alreadyRewardedToday
        }

        progress.extraDailyTaskTokens -= 1
        let extraIndex = progress.rewardedPracticeKeys.filter { $0.hasPrefix("\(key)-extra") }.count + 1
        progress.rewardedPracticeKeys.append("\(key)-extra\(extraIndex)")
        progress.lumens += GamificationRules.lumensPerModeSession
        return .rewardedWithExtraTask(
            lumens: GamificationRules.lumensPerModeSession,
            tokensLeft: progress.extraDailyTaskTokens
        )
    }
}
