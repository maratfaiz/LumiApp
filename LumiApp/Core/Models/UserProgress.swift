import Foundation
import SwiftData

/// The single per-device user state record. One instance should exist per
/// installation — there is no multi-profile requirement in the MVP.
@Model
final class UserProgress {
    var xp: Int
    var lumens: Int
    var currentStreakDays: Int
    var bestStreakDays: Int
    var streakFreezesAvailable: Int
    var lastActiveDate: Date?
    var lastAutomaticFreezeDate: Date?
    /// One entry per calendar day a lesson was completed — feeds F31's
    /// weekly grid / monthly calendar and total-lessons stat.
    var lessonCompletionDates: [Date]
    /// Calendar days where a streak freeze bridged a miss — separate from
    /// lessonCompletionDates so F31's calendar can mark them differently.
    var freezeUsedDates: [Date]
    var currentCourseID: String?
    var completedLessonIDs: [String]
    var unlockedMascotSkinIDs: [String]
    var equippedMascotSkinID: String?
    var unlockedSecretTechniqueIDs: [String]
    var favoriteAffirmationIDs: [String]
    /// F33 "Ранняя пташка" — count of lessons finished before 9:00 local time.
    var earlyBirdLessonCount: Int
    var extraDailyTaskTokens: Int
    /// F13 booster — deliberate pay-to-win exception (Product Owner
    /// decision, see ShopCatalog.swift). Consumption in LessonPlayerView
    /// isn't wired yet.
    var lessonHintTokens: Int
    /// Q3 onboarding answer, raw PreferredFormat.rawValue. Only controls
    /// which mode tiles (Дыхание/Аффирмации/Медитация) surface on Home —
    /// never gates access, the user can always reach every mode.
    var preferredFormatRawValue: String?
    /// Given name captured from the Sign in with Apple .fullName scope, if
    /// the user granted it (Apple only returns it on the very first auth).
    var userDisplayName: String?
    /// F32 — achievement IDs already delivered as a local notification, so
    /// NotificationScheduler.notifyAchievementUnlocked fires once per
    /// achievement, not every time completedLessonIDs is checked.
    var notifiedAchievementIDs: [String]

    init(
        xp: Int = 0,
        lumens: Int = 0,
        currentStreakDays: Int = 0,
        bestStreakDays: Int = 0,
        streakFreezesAvailable: Int = GamificationRules.freeFreezeOnOnboardingComplete,
        lastActiveDate: Date? = nil,
        lastAutomaticFreezeDate: Date? = nil,
        lessonCompletionDates: [Date] = [],
        freezeUsedDates: [Date] = [],
        currentCourseID: String? = nil,
        completedLessonIDs: [String] = [],
        unlockedMascotSkinIDs: [String] = [],
        equippedMascotSkinID: String? = nil,
        unlockedSecretTechniqueIDs: [String] = [],
        favoriteAffirmationIDs: [String] = [],
        earlyBirdLessonCount: Int = 0,
        extraDailyTaskTokens: Int = 0,
        lessonHintTokens: Int = 0,
        preferredFormatRawValue: String? = nil,
        userDisplayName: String? = nil,
        notifiedAchievementIDs: [String] = []
    ) {
        self.xp = xp
        self.lumens = lumens
        self.currentStreakDays = currentStreakDays
        self.bestStreakDays = bestStreakDays
        self.streakFreezesAvailable = min(streakFreezesAvailable, GamificationRules.maxStoredStreakFreezes)
        self.lastActiveDate = lastActiveDate
        self.lastAutomaticFreezeDate = lastAutomaticFreezeDate
        self.lessonCompletionDates = lessonCompletionDates
        self.freezeUsedDates = freezeUsedDates
        self.currentCourseID = currentCourseID
        self.completedLessonIDs = completedLessonIDs
        self.unlockedMascotSkinIDs = unlockedMascotSkinIDs
        self.equippedMascotSkinID = equippedMascotSkinID
        self.unlockedSecretTechniqueIDs = unlockedSecretTechniqueIDs
        self.favoriteAffirmationIDs = favoriteAffirmationIDs
        self.earlyBirdLessonCount = earlyBirdLessonCount
        self.extraDailyTaskTokens = extraDailyTaskTokens
        self.lessonHintTokens = lessonHintTokens
        self.preferredFormatRawValue = preferredFormatRawValue
        self.userDisplayName = userDisplayName
        self.notifiedAchievementIDs = notifiedAchievementIDs
    }

    var level: Int { GamificationRules.level(forXP: xp) }
}
