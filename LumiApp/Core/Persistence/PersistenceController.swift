import Foundation
import SwiftData

enum PersistenceController {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([UserProgress.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
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
