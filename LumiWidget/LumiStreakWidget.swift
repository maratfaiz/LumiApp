import AppIntents
import SwiftUI
import WidgetKit

/// F24 — "Серия дней" widget, ported from the design's medium widget with
/// its three states (нет серии / серия активна / давно не заходил).
///
/// Stays configurable via App Intents (long-press → Edit Widget) so the
/// mascot skin can be picked from the home screen — the same skins as the
/// in-app Wardrobe (F22), rendered from this target's own asset catalog.
enum WidgetSkinOption: String, AppEnum {
    case none
    case classic
    case sport
    case musician
    case scientist
    case night
    case traveler
    case cosmonaut
    case wizard
    case lucky

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Образ Луми"
    static var caseDisplayRepresentations: [WidgetSkinOption: DisplayRepresentation] = [
        .none: "Как на экране (по состоянию)",
        .classic: "Классика",
        .sport: "Спортивный костюм",
        .musician: "Музыкант",
        .scientist: "Учёный",
        .night: "Ночной образ",
        .traveler: "Путешественник",
        .cosmonaut: "Костюм космонавта",
        .wizard: "Мантия волшебника",
        .lucky: "Талисман удачи",
    ]

    var assetName: String? {
        switch self {
        case .none: return nil
        case .classic: return "skin-classic"
        case .sport: return "skin-sport"
        case .musician: return "skin-musician"
        case .scientist: return "skin-scientist"
        case .night: return "skin-night"
        case .traveler: return "skin-traveler"
        case .cosmonaut: return "skin-cosmonaut"
        case .wizard: return "skin-wizard"
        case .lucky: return "skin-lucky"
        }
    }
}

struct StreakWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Образ Луми на виджете"
    static var description = IntentDescription("Выбери, в каком образе Луми появится на виджете.")

    @Parameter(title: "Образ", default: .none)
    var skin: WidgetSkinOption
}

enum StreakState {
    /// состояние А — серии ещё нет
    case fresh
    /// состояние Б — серия активна
    case active
    /// состояние В — давно не заходил (2+ дня)
    case awaitingReturn

    init(_ snapshot: LumiWidgetSnapshot) {
        if snapshot.daysSinceLastActive >= 2 {
            self = .awaitingReturn
        } else if snapshot.streakCount > 0 {
            self = .active
        } else {
            self = .fresh
        }
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let snapshot: LumiWidgetSnapshot
    let skinAssetName: String?
}

struct StreakProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, snapshot: .sample, skinAssetName: nil)
    }

    func snapshot(for configuration: StreakWidgetConfigurationIntent, in context: Context) async -> StreakEntry {
        StreakEntry(date: .now, snapshot: LumiWidgetStore.load(), skinAssetName: configuration.skin.assetName)
    }

    func timeline(for configuration: StreakWidgetConfigurationIntent, in context: Context) async -> Timeline<StreakEntry> {
        let entry = StreakEntry(date: .now, snapshot: LumiWidgetStore.load(), skinAssetName: configuration.skin.assetName)
        // Streak state only changes at day boundaries; refresh after midnight.
        let midnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? .now.addingTimeInterval(3600)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

struct WeekStripView: View {
    let statuses: [LumiDayStatus]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(statuses.enumerated()), id: \.offset) { _, status in
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(status == .empty ? Color.white.opacity(0.16) : Color.white.opacity(0.92))
                    .frame(width: 22, height: 22)
                    .overlay {
                        switch status {
                        case .done:
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(LumiColor.purple2)
                        case .freeze:
                            WidgetIcon(name: "icon-freeze", systemFallback: "snowflake", size: 12, color: Color(hex: 0x4A9FE0))
                        case .empty:
                            EmptyView()
                        }
                    }
            }
        }
    }
}

struct LumiStreakWidgetView: View {
    let entry: StreakEntry

    private var state: StreakState { StreakState(entry.snapshot) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
                .frame(maxWidth: 190, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)

            mascot
                .resizable()
                .scaledToFit()
                .frame(width: mascotSize, height: mascotSize)
                .padding(.trailing, -6)
                .padding(.bottom, -8)
        }
        .containerBackground(for: .widget) {
            LumiWidgetGradient.streakWarm
        }
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .fresh:
            VStack(alignment: .leading, spacing: 8) {
                Text("Начни серию\nсегодня")
                    .font(.lumi(17, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                WeekStripView(statuses: Array(repeating: .empty, count: 7))
            }
        case .active:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    WidgetIcon(name: "icon-streak", systemFallback: "flame.fill", size: 26, color: .white)
                    Text("\(entry.snapshot.streakCount)")
                        .font(.lumi(34, weight: .heavy))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                Text(RussianPlural.daysInARow(entry.snapshot.streakCount))
                    .font(.lumi(12.5, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                WeekStripView(statuses: entry.snapshot.weekStatuses)
                    .padding(.top, 4)
            }
        case .awaitingReturn:
            Text("Луми ждёт тебя,\nкогда будешь готов(а)\nпродолжить")
                .font(.lumi(15.5, weight: .bold))
                .foregroundStyle(.white)
                .lineSpacing(2)
        }
    }

    /// The configured skin wins when the user picked one; otherwise the
    /// pose follows the widget's state, as in the design.
    private var mascot: Image {
        if let skinAssetName = entry.skinAssetName {
            return Image(skinAssetName)
        }
        switch state {
        case .fresh: return Image("mascot-welcome")
        case .active: return Image("mascot-joy")
        case .awaitingReturn: return Image("mascot-ob1")
        }
    }

    private var mascotSize: CGFloat {
        state == .awaitingReturn ? 118 : 132
    }
}

struct LumiStreakWidget: Widget {
    let kind = "LumiStreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StreakWidgetConfigurationIntent.self, provider: StreakProvider()) { entry in
            LumiStreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Луми — серия дней")
        .description("Текущая серия и повод вернуться сегодня. Долгий тап — выбрать образ Луми.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    LumiStreakWidget()
} timeline: {
    StreakEntry(date: .now, snapshot: .freshStart, skinAssetName: nil)
    StreakEntry(date: .now, snapshot: .sample, skinAssetName: nil)
    StreakEntry(
        date: .now,
        snapshot: LumiWidgetSnapshot(
            streakCount: 4,
            weekStatuses: [.done, .done, .done, .done, .empty, .empty, .empty],
            daysSinceLastActive: 3,
            courseTitle: "", lessonTitle: "", lessonProgress: 0,
            lessonCompletedToday: false, level: 1, levelProgress: 0, lumens: 0
        ),
        skinAssetName: nil
    )
}
