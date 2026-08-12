import SwiftUI
import WidgetKit

@main
struct LumiWidgetBundle: WidgetBundle {
    var body: some Widget {
        LumiStreakWidget()
        LumiLessonWidget()
        LumiProfileWidget()
    }
}
