import SwiftData
import SwiftUI

@main
struct LumiAppApp: App {
    let modelContainer = PersistenceController.makeContainer()

    init() {
        GoogleAuth.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
