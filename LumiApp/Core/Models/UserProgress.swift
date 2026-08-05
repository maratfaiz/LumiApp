import Foundation
import SwiftData

/// The single per-device user state record. One instance should exist per
/// installation — there is no multi-profile requirement in the MVP.
@Model
final class UserProgress {
    var xp: Int
    var lumens: Int
    var currentStreakDays: Int
    var streakFreezesAvailable: Int
    var lastActiveDate: Date?
    var lastAutomaticFreezeDate: Date?
    var currentCourseID: String?
    var completedLessonIDs: [String]
    var unlockedMascotSkinIDs: [String]
    /// Q3 onboarding answer, raw PreferredFormat.rawValue. Only controls
    /// which mode tiles (Дыхание/Аффирмации/Медитация) surface on Home —
    /// never gates access, the user can always reach every mode.
    var preferredFormatRawValue: String?

    init(
        xp: Int = 0,
        lumens: Int = 0,
        currentStreakDays: Int = 0,
        streakFreezesAvailable: Int = GamificationRules.freeFreezeOnOnboardingComplete,
        lastActiveDate: Date? = nil,
        lastAutomaticFreezeDate: Date? = nil,
        currentCourseID: String? = nil,
        completedLessonIDs: [String] = [],
        unlockedMascotSkinIDs: [String] = [],
        preferredFormatRawValue: String? = nil
    ) {
        self.xp = xp
        self.lumens = lumens
        self.currentStreakDays = currentStreakDays
        self.streakFreezesAvailable = min(streakFreezesAvailable, GamificationRules.maxStoredStreakFreezes)
        self.lastActiveDate = lastActiveDate
        self.lastAutomaticFreezeDate = lastAutomaticFreezeDate
        self.currentCourseID = currentCourseID
        self.completedLessonIDs = completedLessonIDs
        self.unlockedMascotSkinIDs = unlockedMascotSkinIDs
        self.preferredFormatRawValue = preferredFormatRawValue
    }

    var level: Int { GamificationRules.level(forXP: xp) }
}
