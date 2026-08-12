import Foundation
import SwiftData

/// One day cell in the streak week strip.
enum LumiDayStatus {
    case done
    case freeze
    case empty
}

/// Everything the three widgets render. Built from the same SwiftData
/// store the app writes to (shared through the App Group container), so
/// there is no second copy of the data to keep in sync — the app only has
/// to call `WidgetSync.refresh()` after a change.
struct LumiWidgetSnapshot {
    var streakCount: Int
    var weekStatuses: [LumiDayStatus]
    var daysSinceLastActive: Int

    var courseTitle: String
    var lessonTitle: String
    var lessonProgress: Double
    var lessonCompletedToday: Bool

    var level: Int
    var levelProgress: Double
    var lumens: Int

    /// Shown in Xcode previews and in the widget gallery placeholder.
    static let sample = LumiWidgetSnapshot(
        streakCount: 7,
        weekStatuses: [.done, .done, .done, .freeze, .done, .done, .empty],
        daysSinceLastActive: 0,
        courseTitle: "Курс 1 · Работа с внутренним критиком",
        lessonTitle: "Урок 3. Замечаем критику",
        lessonProgress: 0.4,
        lessonCompletedToday: false,
        level: 3,
        levelProgress: 0.6,
        lumens: 1230
    )

    static let freshStart = LumiWidgetSnapshot(
        streakCount: 0,
        weekStatuses: Array(repeating: .empty, count: 7),
        daysSinceLastActive: 0,
        courseTitle: "",
        lessonTitle: "",
        lessonProgress: 0,
        lessonCompletedToday: false,
        level: 1,
        levelProgress: 0,
        lumens: 0
    )
}

enum LumiWidgetStore {
    /// Reads the app's SwiftData store through the shared App Group
    /// container. Falls back to the "fresh start" state when the app has
    /// never run (nothing to read yet).
    static func load(calendar: Calendar = .current, now: Date = .now) -> LumiWidgetSnapshot {
        let container = PersistenceController.makeContainer()
        let context = ModelContext(container)
        guard let progress = try? context.fetch(FetchDescriptor<UserProgress>()).first else {
            return .freshStart
        }
        return snapshot(from: progress, calendar: calendar, now: now)
    }

    static func snapshot(from progress: UserProgress, calendar: Calendar = .current, now: Date = .now) -> LumiWidgetSnapshot {
        let today = calendar.startOfDay(for: now)
        let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }

        let statuses: [LumiDayStatus] = days.map { day in
            if progress.lessonCompletionDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
                return .done
            }
            if progress.freezeUsedDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) {
                return .freeze
            }
            return .empty
        }

        let daysSinceLastActive: Int = {
            guard let lastActive = progress.lastActiveDate else { return 0 }
            return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastActive), to: today).day ?? 0
        }()

        let course = CourseCatalog.courses.first { $0.id == progress.currentCourseID }
        let completed = Set(progress.completedLessonIDs)
        let nextLesson = course?.lessons.first { !completed.contains($0.id) }
        let doneInCourse = course?.lessons.filter { completed.contains($0.id) }.count ?? 0

        let lessonProgress: Double = {
            guard let course, !course.lessons.isEmpty else { return 0 }
            return Double(doneInCourse) / Double(course.lessons.count)
        }()

        let thresholds = GamificationRules.levelThresholds
        let levelProgress: Double = {
            guard let nextIndex = thresholds.firstIndex(where: { $0 > progress.xp }) else { return 1 }
            let lower = thresholds[max(nextIndex - 1, 0)]
            let upper = thresholds[nextIndex]
            guard upper > lower else { return 1 }
            return Double(progress.xp - lower) / Double(upper - lower)
        }()

        return LumiWidgetSnapshot(
            streakCount: progress.currentStreakDays,
            weekStatuses: statuses,
            daysSinceLastActive: daysSinceLastActive,
            courseTitle: course.map { "Курс \($0.number) · \($0.title)" } ?? "",
            lessonTitle: nextLesson.map { "Урок \($0.indexInCourse). \($0.title)" } ?? "",
            lessonProgress: lessonProgress,
            lessonCompletedToday: progress.lessonCompletionDates.contains { calendar.isDate($0, inSameDayAs: today) },
            level: progress.level,
            levelProgress: levelProgress,
            lumens: progress.lumens
        )
    }
}
