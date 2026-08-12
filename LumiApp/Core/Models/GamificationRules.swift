import Foundation

/// Константы экономики. Держим единственным источником правды — не
/// разносить магические числа по экранам.
///
/// ## Баланс (пересчитан)
///
/// Раньше практики приносили 45 люменов в день (3 × 15) против 10 за урок,
/// то есть «прокликать» три практики было в 4,5 раза выгоднее, чем пройти
/// урок, а весь магазин (≈920) закрывался за три недели вообще без уроков.
/// Это переворачивало приоритеты приложения: уроки — суть продукта,
/// практики — поддержка.
///
/// Теперь:
///
/// | Источник | Люмены | Ограничение |
/// |---|---|---|
/// | Урок | 15 | Только первое прохождение |
/// | Курс целиком | 75 | Один раз за курс |
/// | Практика | 10 | Раз в день на практику, максимум 2 награды в день |
/// | Уровень | 25–80 | Один раз за уровень |
/// | Достижение | 20–100 | Один раз |
///
/// Дневной доход активного пользователя: 15 (урок) + 20 (две практики) = 35.
/// Весь контент курсов даёт 20 × 15 + 4 × 75 = 600.
/// Всё покупаемое в магазине стоит 920 (6 образов + 3 техники + бустеры),
/// то есть гардероб — цель на несколько недель, а не на три дня.
enum GamificationRules {
    static let xpPerLesson = 15
    static let lumensPerLesson = 15
    static let lumensBonusPerCourseCompletion = 75
    /// F26/F27/F29 — Дыхание, Аффирмации, Медитация дают только люмены, без XP.
    static let lumensPerModeSession = 10
    /// Сколько практик в день вообще могут принести люмены. Каждая
    /// практика — не чаще раза в день, и суммарно не больше этого числа.
    static let maxRewardedPracticesPerDay = 2
    /// XP за практику нет — иначе уровни росли бы в обход уроков.
    static let xpPerJournalEntry = 5

    /// Порог XP, с которого начинается каждый уровень. Индекс 0 — уровень 1.
    static let levelThresholds = [0, 30, 70, 120, 180, 260, 360, 480, 620, 800]

    static let streakFreezePriceLumens = 30
    static let secretTechniquePriceLumens = 40
    /// Обычные и редкие образы; эпические открываются за уроки, не за люмены.
    static let accessoryPriceRange = 80...200

    static let maxStoredStreakFreezes = 2
    static let freeFreezeOnOnboardingComplete = 1
    static let automaticFreezeIntervalDays = 7

    static func level(forXP xp: Int) -> Int {
        var level = 1
        for (index, threshold) in levelThresholds.enumerated() where xp >= threshold {
            level = index + 1
        }
        return level
    }

    static func xpToNextLevel(currentXP xp: Int) -> Int? {
        guard let nextThreshold = levelThresholds.first(where: { $0 > xp }) else { return nil }
        return nextThreshold - xp
    }

    /// Прогресс внутри текущего уровня, 0...1.
    static func levelProgress(currentXP xp: Int) -> Double {
        guard let nextIndex = levelThresholds.firstIndex(where: { $0 > xp }) else { return 1 }
        let lower = levelThresholds[max(nextIndex - 1, 0)]
        let upper = levelThresholds[nextIndex]
        guard upper > lower else { return 1 }
        return Double(xp - lower) / Double(upper - lower)
    }
}
