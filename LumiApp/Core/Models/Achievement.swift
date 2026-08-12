import Foundation

/// Достижение с настоящей наградой. Раньше их было 6 из 8, они ничего не
/// давали и половина условий была недостижима, потому что механик под них
/// в приложении не существовало. Теперь каждое достижение опирается на
/// реально считающийся показатель и приносит люмены или бустер.
struct Achievement: Identifiable {
    let id: String
    let title: String
    let conditionDescription: String
    /// Награда за разблокировку — выдаётся один раз (`AchievementService`).
    let rewardLumens: Int
    let rewardFreezes: Int
    let rewardHints: Int
    /// Текущий прогресс к цели, 0...1 — для полоски в списке «впереди».
    let progress: (UserProgress) -> Double
    let isUnlocked: (UserProgress) -> Bool

    init(
        id: String,
        title: String,
        conditionDescription: String,
        rewardLumens: Int = 0,
        rewardFreezes: Int = 0,
        rewardHints: Int = 0,
        progress: @escaping (UserProgress) -> Double = { _ in 0 },
        isUnlocked: @escaping (UserProgress) -> Bool
    ) {
        self.id = id
        self.title = title
        self.conditionDescription = conditionDescription
        self.rewardLumens = rewardLumens
        self.rewardFreezes = rewardFreezes
        self.rewardHints = rewardHints
        self.progress = progress
        self.isUnlocked = isUnlocked
    }

    var rewardSummary: String {
        var parts: [String] = []
        if rewardLumens > 0 { parts.append("+\(rewardLumens) ✦") }
        if rewardFreezes > 0 { parts.append("+\(RussianPlural.freezes(rewardFreezes))") }
        if rewardHints > 0 { parts.append("+\(rewardHints) подсказка") }
        return parts.joined(separator: " · ")
    }
}

private func ratio(_ value: Int, _ target: Int) -> Double {
    guard target > 0 else { return 0 }
    return min(Double(value) / Double(target), 1)
}

enum AchievementCatalog {
    static let all: [Achievement] = [
        Achievement(
            id: "achievement-first-lesson",
            title: "Первый урок",
            conditionDescription: "Пройти первый урок",
            rewardLumens: 20,
            progress: { ratio($0.completedLessonIDs.count, 1) },
            isUnlocked: { !$0.completedLessonIDs.isEmpty }
        ),
        Achievement(
            id: "achievement-lessons-10",
            title: "Десять уроков",
            conditionDescription: "Пройти 10 уроков",
            rewardLumens: 40,
            progress: { ratio($0.completedLessonIDs.count, 10) },
            isUnlocked: { $0.completedLessonIDs.count >= 10 }
        ),
        Achievement(
            id: "achievement-course-complete",
            title: "Курс пройден",
            conditionDescription: "Завершить курс целиком",
            rewardLumens: 50,
            progress: { progress in
                let best = CourseCatalog.courses
                    .filter { !$0.lessons.isEmpty }
                    .map { course -> Double in
                        let done = course.lessons.filter { progress.completedLessonIDs.contains($0.id) }.count
                        return ratio(done, course.lessons.count)
                    }
                    .max()
                return best ?? 0
            },
            isUnlocked: { progress in
                CourseCatalog.courses.contains { course in
                    !course.lessons.isEmpty
                        && Set(course.lessons.map(\.id)).isSubset(of: Set(progress.completedLessonIDs))
                }
            }
        ),
        Achievement(
            id: "achievement-streak-3",
            title: "Три дня подряд",
            conditionDescription: "Серия 3 дня без пропуска",
            rewardLumens: 20,
            progress: { ratio($0.bestStreakDays, 3) },
            isUnlocked: { $0.bestStreakDays >= 3 }
        ),
        Achievement(
            id: "achievement-streak-7",
            title: "7 дней подряд",
            conditionDescription: "Серия 7 дней без пропуска",
            rewardLumens: 30,
            rewardFreezes: 1,
            progress: { ratio($0.bestStreakDays, 7) },
            isUnlocked: { $0.bestStreakDays >= 7 }
        ),
        Achievement(
            id: "achievement-streak-30",
            title: "30 дней подряд",
            conditionDescription: "Серия 30 дней",
            rewardLumens: 100,
            rewardFreezes: 1,
            progress: { ratio($0.bestStreakDays, 30) },
            isUnlocked: { $0.bestStreakDays >= 30 }
        ),
        Achievement(
            id: "achievement-early-bird",
            title: "Ранняя пташка",
            conditionDescription: "3 урока до 9 утра",
            rewardLumens: 25,
            progress: { ratio($0.earlyBirdLessonCount, 3) },
            isUnlocked: { $0.earlyBirdLessonCount >= 3 }
        ),
        // Раньше здесь была «Ночная звезда» за уроки после 22:00. Убрано
        // намеренно: награда за ночное использование подкрепляет и
        // нарушенный сон, и зависимость от приложения — это прямо
        // противоречит ценности «поддержка вместо давления».
        // Вместо этого подкрепляем возвращение после пропуска — то самое
        // поведение, на котором обычно теряются пользователи, и без стыда.
        Achievement(
            id: "achievement-comeback",
            title: "Вернулся(ась)",
            conditionDescription: "Продолжить занятия после перерыва",
            rewardLumens: 25,
            progress: { ratio($0.comebackCount, 1) },
            isUnlocked: { $0.comebackCount >= 1 }
        ),
        Achievement(
            id: "achievement-practices-10",
            title: "Практикующий",
            conditionDescription: "10 завершённых практик",
            rewardLumens: 30,
            rewardHints: 1,
            progress: { ratio($0.practiceSessionCount, 10) },
            isUnlocked: { $0.practiceSessionCount >= 10 }
        ),
        Achievement(
            id: "achievement-journal-5",
            title: "Дневник × 5",
            conditionDescription: "5 записей в дневнике эмоций",
            rewardLumens: 30,
            progress: { ratio($0.journalEntryCount, 5) },
            isUnlocked: { $0.journalEntryCount >= 5 }
        ),
        Achievement(
            id: "achievement-journal-20",
            title: "Дневник × 20",
            conditionDescription: "20 записей в дневнике эмоций",
            rewardLumens: 60,
            progress: { ratio($0.journalEntryCount, 20) },
            isUnlocked: { $0.journalEntryCount >= 20 }
        ),
        Achievement(
            id: "achievement-favorites-5",
            title: "Свои слова",
            conditionDescription: "5 аффирмаций в избранном",
            rewardLumens: 20,
            progress: { ratio($0.favoriteAffirmationIDs.count, 5) },
            isUnlocked: { $0.favoriteAffirmationIDs.count >= 5 }
        ),
        Achievement(
            id: "achievement-wardrobe-3",
            title: "Гардероб Луми",
            conditionDescription: "Открыть 3 образа",
            rewardLumens: 40,
            progress: { progress in
                ratio(ShopCatalog.accessories.filter { ShopService.isOwned($0, progress: progress) }.count, 3)
            },
            isUnlocked: { progress in
                ShopCatalog.accessories.filter { ShopService.isOwned($0, progress: progress) }.count >= 3
            }
        ),
        Achievement(
            id: "achievement-level-5",
            title: "Уровень 5",
            conditionDescription: "Дойти до пятого уровня",
            rewardLumens: 50,
            progress: { ratio($0.level, 5) },
            isUnlocked: { $0.level >= 5 }
        ),
    ]

    static func achievement(id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}

/// Выдача наград за достижения. Отдельно от каталога, потому что каталог —
/// это описание условий, а тут происходит изменение состояния.
enum AchievementService {
    /// Выдаёт награды за все разблокированные, но ещё не полученные
    /// достижения. Идемпотентно. Возвращает новые достижения — экран
    /// показывает их, а `NotificationScheduler` шлёт уведомление.
    @discardableResult
    static func claimUnlocked(for progress: UserProgress) -> [Achievement] {
        let newlyUnlocked = AchievementCatalog.all.filter {
            $0.isUnlocked(progress) && !progress.claimedAchievementIDs.contains($0.id)
        }

        for achievement in newlyUnlocked {
            progress.claimedAchievementIDs.append(achievement.id)
            progress.lumens += achievement.rewardLumens
            if achievement.rewardFreezes > 0 {
                progress.streakFreezesAvailable = min(
                    progress.streakFreezesAvailable + achievement.rewardFreezes,
                    GamificationRules.maxStoredStreakFreezes
                )
            }
            progress.hintTokens(add: achievement.rewardHints)
        }

        return newlyUnlocked
    }
}
