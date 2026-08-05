import Foundation

/// Constants from docs/product/Lumi_Gamification_Economy.docx.
/// Keep this the single source of truth — don't scatter magic numbers.
enum GamificationRules {
    static let xpPerLesson = 10
    static let lumensPerLesson = 10
    static let lumensBonusPerCourseCompletion = 50

    /// XP threshold to *reach* each level. Index 0 is level 1 (always unlocked).
    static let levelThresholds = [0, 30, 70, 120, 180]

    static let streakFreezePriceLumens = 30
    static let secretTechniquePriceLumens = 40
    /// Common/rare accessories only — epic accessories unlock by lessons
    /// completed instead (20/30/40), never by lumens. See ShopCatalog.swift.
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
}
