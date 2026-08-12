import Foundation
import WidgetKit

/// F24 — the widgets read the same SwiftData store as the app through the
/// App Group container, so they never need their own copy of the data;
/// they only need to be told *when* to re-read it.
///
/// Call this after any change to streak / lesson / profile state.
enum WidgetSync {
    static func refresh() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
