import SwiftUI
import WidgetKit

/// F24 — "Сегодняшний урок" widget from the design: pushes the user to the
/// one concrete next step in their current course, or says the day is done.
struct LessonEntry: TimelineEntry {
    let date: Date
    let snapshot: LumiWidgetSnapshot
}

struct LessonProvider: TimelineProvider {
    func placeholder(in context: Context) -> LessonEntry {
        LessonEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (LessonEntry) -> Void) {
        completion(LessonEntry(date: .now, snapshot: LumiWidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LessonEntry>) -> Void) {
        let entry = LessonEntry(date: .now, snapshot: LumiWidgetStore.load())
        let midnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }
}

struct LumiLessonWidgetView: View {
    let snapshot: LumiWidgetSnapshot

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WidgetStarField(stars: WidgetStarPresets.mediumDeep)

            content
                .frame(maxWidth: 190, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(snapshot.lessonCompletedToday ? "mascot-joy" : "mascot-lesson")
                .resizable()
                .scaledToFit()
                .frame(width: 148, height: 148)
                .padding(.trailing, -10)
                .padding(.bottom, -12)
        }
        .containerBackground(for: .widget) {
            LumiWidgetGradient.deep
        }
    }

    @ViewBuilder private var content: some View {
        if snapshot.lessonCompletedToday {
            Text("Урок пройден.\nЗагляни завтра")
                .font(.lumi(16.5, weight: .heavy))
                .foregroundStyle(.white)
                .lineSpacing(2)
        } else if snapshot.lessonTitle.isEmpty {
            Text("Начни свой первый урок")
                .font(.lumi(16.5, weight: .heavy))
                .foregroundStyle(.white)
                .lineSpacing(2)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(snapshot.courseTitle)
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                Text(snapshot.lessonTitle)
                    .font(.lumi(16, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineSpacing(1)
                    .lineLimit(2)

                GeometryReader { geo in
                    Capsule()
                        .fill(.white.opacity(0.16))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [LumiColor.purple1, LumiColor.purpleLight],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * snapshot.lessonProgress)
                        }
                }
                .frame(width: 150, height: 5)

                HStack(spacing: 4) {
                    Text("Открой Луми")
                        .font(.lumi(12.5, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(.white.opacity(0.14), in: Capsule())
                .padding(.top, 2)
            }
        }
    }
}

struct LumiLessonWidget: Widget {
    let kind = "LumiLessonWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessonProvider()) { entry in
            LumiLessonWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Луми — сегодняшний урок")
        .description("Показывает конкретный следующий шаг в текущем курсе.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    LumiLessonWidget()
} timeline: {
    LessonEntry(date: .now, snapshot: .sample)
    LessonEntry(
        date: .now,
        snapshot: LumiWidgetSnapshot(
            streakCount: 7, weekStatuses: [], daysSinceLastActive: 0,
            courseTitle: "", lessonTitle: "", lessonProgress: 0,
            lessonCompletedToday: true, level: 3, levelProgress: 0.6, lumens: 1230
        )
    )
}
