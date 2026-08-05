import Foundation
import SwiftData

enum PersistenceController {
    /// Stored in the App Group container (not the app's default location)
    /// so the F24 widget extension can read the same data.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([UserProgress.self])
        let storeURL = AppGroup.containerURL.appending(path: "LumiApp.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    @MainActor
    static func makePreviewContainer() -> ModelContainer {
        let schema = Schema([UserProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.insert(UserProgress())
        return container
    }
}
