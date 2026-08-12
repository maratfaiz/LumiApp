import Foundation
import SwiftData

enum PersistenceController {
    static let schema = Schema([UserProgress.self, JournalEntry.self])

    /// Stored in the App Group container (not the app's default location)
    /// so the F24 widget extension can read the same data.
    static func makeContainer() -> ModelContainer {
        let storeURL = AppGroup.containerURL.appending(path: "LumiApp.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Схема изменилась несовместимо со старым файлом (это возможно
            // только на дев-сборках — приложение ещё не в App Store).
            // Раньше здесь был fatalError, то есть приложение переставало
            // запускаться до переустановки. Пересоздаём хранилище: данных
            // за пределами устройства нет, терять нечего, а падать на старте
            // хуже.
            try? FileManager.default.removeItem(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Failed to create SwiftData ModelContainer: \(error)")
            }
        }
    }

    @MainActor
    static func makePreviewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.insert(
            UserProgress(
                lumens: 240,
                currentStreakDays: 3,
                streakFreezesAvailable: 1,
                currentCourseID: CourseCatalog.courses.first?.id
            )
        )
        return container
    }
}
