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
    /// Свои аффирмации, добавленные пользователем. Попадают в колоду
    /// наравне с каталожными и автоматически считаются избранными.
    var customAffirmations: [String]
    /// F33 "Ранняя пташка" — count of lessons finished before 9:00 local time.
    var earlyBirdLessonCount: Int
    /// Уроки, законченные после 22:00. Показывается в статистике; на
    /// достижения намеренно не влияет — награждать за ночное использование
    /// значит подкреплять нарушенный сон и зависимость от приложения.
    var lateNightLessonCount: Int
    /// Сколько раз человек возвращался к занятиям после перерыва в 2+ дня.
    /// Возвращение — то самое поведение, которое стоит подкреплять.
    var comebackCount: Int
    /// Сколько практик (дыхание/аффирмации/медитация) доведено до конца —
    /// считается независимо от того, была ли за них награда.
    var practiceSessionCount: Int
    /// F13 booster — one extra *rewarded* practice session on a day whose
    /// normal reward for that practice is already used up
    /// (see `PracticeRewardLedger`).
    var extraDailyTaskTokens: Int
    /// F13 booster — deliberate pay-to-win exception (Product Owner
    /// decision, see ShopCatalog.swift). Spent in LessonPlayerView to
    /// reveal the lesson's worked example.
    var lessonHintTokens: Int
    /// Lessons whose hint has already been paid for — a revealed hint stays
    /// revealed, so a replay never charges twice.
    var hintedLessonIDs: [String]
    /// One entry per already-rewarded practice session, keyed
    /// `<practice>-<yyyy-MM-dd>` (plus an `-extraN` suffix when an
    /// "extra task" token paid for it). Drives the daily reward limit.
    var rewardedPracticeKeys: [String]
    /// F30 "Дневник эмоций" (unlocked in the shop) — number of saved
    /// entries, kept here so achievements can read it without a fetch.
    var journalEntryCount: Int
    /// Уровни, награда за которые уже выдана (`LevelSystem`).
    var claimedLevelRewards: [Int]
    /// Достижения, награда за которые уже выдана (`AchievementService`).
    var claimedAchievementIDs: [String]
    /// Ответ на 4-й вопрос онбординга — влияет на подбор «Мысли дня» и
    /// рекомендаций в магазине.
    var goalRawValue: String?
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
        customAffirmations: [String] = [],
        earlyBirdLessonCount: Int = 0,
        lateNightLessonCount: Int = 0,
        comebackCount: Int = 0,
        practiceSessionCount: Int = 0,
        extraDailyTaskTokens: Int = 0,
        lessonHintTokens: Int = 0,
        hintedLessonIDs: [String] = [],
        rewardedPracticeKeys: [String] = [],
        journalEntryCount: Int = 0,
        claimedLevelRewards: [Int] = [],
        claimedAchievementIDs: [String] = [],
        goalRawValue: String? = nil,
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
        self.customAffirmations = customAffirmations
        self.earlyBirdLessonCount = earlyBirdLessonCount
        self.lateNightLessonCount = lateNightLessonCount
        self.comebackCount = comebackCount
        self.practiceSessionCount = practiceSessionCount
        self.extraDailyTaskTokens = extraDailyTaskTokens
        self.lessonHintTokens = lessonHintTokens
        self.hintedLessonIDs = hintedLessonIDs
        self.rewardedPracticeKeys = rewardedPracticeKeys
        self.journalEntryCount = journalEntryCount
        self.claimedLevelRewards = claimedLevelRewards
        self.claimedAchievementIDs = claimedAchievementIDs
        self.goalRawValue = goalRawValue
        self.preferredFormatRawValue = preferredFormatRawValue
        self.userDisplayName = userDisplayName
        self.notifiedAchievementIDs = notifiedAchievementIDs
    }

    // Этот файл компилируется и в таргете виджета, поэтому здесь только то,
    // что доступно обоим таргетам. Свойства, завязанные на уровни и ответы
    // онбординга, живут в расширениях рядом с их типами.
    var level: Int { GamificationRules.level(forXP: xp) }
    var levelProgress: Double { GamificationRules.levelProgress(currentXP: xp) }
}
