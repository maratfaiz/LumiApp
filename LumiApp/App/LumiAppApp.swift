import SwiftData
import SwiftUI

@main
struct LumiAppApp: App {
    let modelContainer = PersistenceController.makeContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
