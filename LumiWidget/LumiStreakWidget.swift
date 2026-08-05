import SwiftData
import SwiftUI
import WidgetKit

/// F24 — home-screen widget, 2 preview states per spec: a normal/baseline
/// view and one shown once the user has an active streak. Reads the same
/// SwiftData store as the app via the App Group container (AppGroup.swift,
/// PersistenceController.swift — shared source files, see project.yml).
struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreakDays: Int
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, currentStreakDays: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? entry.date.addingTimeInterval(4 * 3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> StreakEntry {
        let container = PersistenceController.makeContainer()
        let context = ModelContext(container)
        let progress = try? context.fetch(FetchDescriptor<UserProgress>()).first
        return StreakEntry(date: .now, currentStreakDays: progress?.currentStreakDays ?? 0)
    }
}

struct LumiStreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        Group {
            if entry.currentStreakDays > 0 {
                streakView
            } else {
                normalView
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0.07, green: 0.05, blue: 0.16)
        }
    }

    private var normalView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 26))
                .foregroundStyle(.purple)
            Text("Луми")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
            Text("Начни серию сегодня")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var streakView: some View {
        VStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
            Text("\(entry.currentStreakDays)")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(dayLabel)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }

    private var dayLabel: String {
        entry.currentStreakDays == 1 ? "день подряд" : "дней подряд"
    }
}

struct LumiStreakWidget: Widget {
    let kind = "LumiStreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            LumiStreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Луми — серия дней")
        .description("Показывает текущую серию дней подряд.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    LumiStreakWidget()
} timeline: {
    StreakEntry(date: .now, currentStreakDays: 0)
    StreakEntry(date: .now, currentStreakDays: 7)
}
