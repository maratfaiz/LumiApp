import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

/// F24 — home-screen widget, 2 preview states per spec: a normal/baseline
/// view and one shown once the user has an active streak. Reads the same
/// SwiftData store as the app via the App Group container (AppGroup.swift,
/// PersistenceController.swift — shared source files, see project.yml).
///
/// Configurable via App Intents (long-press the widget → Edit Widget) so
/// the mascot skin shown can be picked without leaving the home screen —
/// this is the "make widgets from the app" ask: the same skins from the
/// in-app Wardrobe (F22), rendered here from a copy of the PNGs in this
/// target's own Assets.xcassets (a widget extension has its own bundle,
/// it can't reach into the main app's asset catalog by name).
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
        .none: "Обычная звезда",
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

struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreakDays: Int
    let skinAssetName: String?
}

struct StreakProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, currentStreakDays: 3, skinAssetName: nil)
    }

    func snapshot(for configuration: StreakWidgetConfigurationIntent, in context: Context) async -> StreakEntry {
        currentEntry(configuration: configuration)
    }

    func timeline(for configuration: StreakWidgetConfigurationIntent, in context: Context) async -> Timeline<StreakEntry> {
        let entry = currentEntry(configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? entry.date.addingTimeInterval(4 * 3600)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func currentEntry(configuration: StreakWidgetConfigurationIntent) -> StreakEntry {
        let container = PersistenceController.makeContainer()
        let context = ModelContext(container)
        let progress = try? context.fetch(FetchDescriptor<UserProgress>()).first
        return StreakEntry(
            date: .now,
            currentStreakDays: progress?.currentStreakDays ?? 0,
            skinAssetName: configuration.skin.assetName
        )
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
            mascotIcon(size: 40, systemFallback: "star.fill", fallbackColor: .purple)
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
            mascotIcon(size: 34, systemFallback: "flame.fill", fallbackColor: .orange)
            Text("\(entry.currentStreakDays)")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(dayLabel)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
    }

    @ViewBuilder
    private func mascotIcon(size: CGFloat, systemFallback: String, fallbackColor: Color) -> some View {
        if let skinAssetName = entry.skinAssetName {
            Image(skinAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: systemFallback)
                .font(.system(size: size * 0.7))
                .foregroundStyle(fallbackColor)
        }
    }

    private var dayLabel: String {
        entry.currentStreakDays == 1 ? "день подряд" : "дней подряд"
    }
}

struct LumiStreakWidget: Widget {
    let kind = "LumiStreakWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StreakWidgetConfigurationIntent.self, provider: StreakProvider()) { entry in
            LumiStreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Луми — серия дней")
        .description("Показывает текущую серию дней подряд. Долгий тап по виджету — выбрать образ Луми.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    LumiStreakWidget()
} timeline: {
    StreakEntry(date: .now, currentStreakDays: 0, skinAssetName: nil)
    StreakEntry(date: .now, currentStreakDays: 7, skinAssetName: nil)
}
