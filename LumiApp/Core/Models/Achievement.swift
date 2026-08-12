import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let conditionDescription: String
    let isUnlocked: (UserProgress) -> Bool
}

/// F33 — "актуальный список" names 6 of 8 achievements; the doc itself
/// flags 2 as open questions ("Дневник × 5" references a mechanic that
/// doesn't exist in the 44-screen prototype, and 2 of 8 are unnamed in the
/// source). Per that doc's own instruction ("нужно уточнить у дизайнера
/// механику до постановки задачи разработчику"), those are deliberately
/// NOT implemented here rather than guessed at.
enum AchievementCatalog {
    static let all: [Achievement] = [
        Achievement(
            id: "achievement-first-lesson",
            title: "Первый урок",
            conditionDescription: "Пройден первый урок",
            isUnlocked: { !$0.completedLessonIDs.isEmpty }
        ),
        Achievement(
            id: "achievement-streak-7",
            title: "7 дней подряд",
            conditionDescription: "Серия 7 дней без пропуска",
            isUnlocked: { $0.bestStreakDays >= 7 }
        ),
        // "1 из 3 раз" is ambiguous in the source doc (unlock-once-out-of-3
        // vs. needs-3-mornings) — reading it as unlock-on-first, matching
        // every other achievement's binary condition.
        Achievement(
            id: "achievement-early-bird",
            title: "Ранняя пташка",
            conditionDescription: "Урок до 9 утра — 1 из 3 раз",
            isUnlocked: { $0.earlyBirdLessonCount >= 1 }
        ),
        Achievement(
            id: "achievement-course-complete",
            title: "Курс пройден",
            conditionDescription: "Завершён курс целиком",
            isUnlocked: { progress in
                CourseCatalog.courses.contains { course in
                    !course.lessons.isEmpty && Set(course.lessons.map(\.id)).isSubset(of: Set(progress.completedLessonIDs))
                }
            }
        ),
        Achievement(
            id: "achievement-streak-30",
            title: "30 дней подряд",
            conditionDescription: "Серия 30 дней",
            isUnlocked: { $0.bestStreakDays >= 30 }
        ),
        // Раньше это достижение не реализовывалось, потому что механики
        // «дневника» в приложении не было. Теперь она есть — техника
        // «Дневник эмоций» покупается в магазине и пишет записи, — так что
        // условие из документа наконец однозначно.
        Achievement(
            id: "achievement-journal-5",
            title: "Дневник × 5",
            conditionDescription: "5 записей в дневнике эмоций",
            isUnlocked: { $0.journalEntryCount >= 5 }
        ),
    ]
}
