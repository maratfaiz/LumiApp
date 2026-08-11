import Foundation

/// Shared container so the F24 widget extension can read the same
/// SwiftData store as the main app. Must match the
/// com.apple.security.application-groups entitlement on both targets.
enum AppGroup {
    static let identifier = "group.com.lumi.app.shared"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("App Group container unavailable — check the com.apple.security.application-groups entitlement.")
        }
        return url
    }
}
