import SwiftUI
import WidgetKit

/// F24 — "Профиль коротко" widget from the design: level, lumens and
/// streak at a glance.
struct ProfileEntry: TimelineEntry {
    let date: Date
    let snapshot: LumiWidgetSnapshot
}

struct ProfileProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProfileEntry {
        ProfileEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProfileEntry) -> Void) {
        completion(ProfileEntry(date: .now, snapshot: LumiWidgetStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProfileEntry>) -> Void) {
        let entry = ProfileEntry(date: .now, snapshot: LumiWidgetStore.load())
        // Profile stats can change any time the app is used.
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(30 * 60))))
    }
}

private struct ProfileRow: View {
    let iconName: String
    let systemFallback: String
    let tint: Color
    let label: String

    var body: some View {
        HStack(spacing: 7) {
            WidgetIcon(name: iconName, systemFallback: systemFallback, size: 15, color: tint)
            Text(label)
                .font(.lumi(13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }
}

struct LumiProfileWidgetView: View {
    let snapshot: LumiWidgetSnapshot

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WidgetStarField(stars: WidgetStarPresets.smallDeep)

            VStack(alignment: .leading, spacing: 9) {
                ProfileRow(
                    iconName: "icon-stats",
                    systemFallback: "chart.bar.fill",
                    tint: LumiColor.textSecondary,
                    label: "Уровень \(snapshot.level)"
                )

                GeometryReader { geo in
                    Capsule()
                        .fill(.white.opacity(0.16))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(LumiColor.yellow)
                                .frame(width: geo.size.width * snapshot.levelProgress)
                        }
                }
                .frame(height: 5)

                ProfileRow(
                    iconName: "icon-lumen",
                    systemFallback: "star.fill",
                    tint: LumiColor.yellow,
                    label: "\(snapshot.lumens)"
                )
                ProfileRow(
                    iconName: "icon-streak",
                    systemFallback: "flame.fill",
                    tint: LumiColor.orange1,
                    label: RussianPlural.days(snapshot.streakCount)
                )
            }
            .frame(maxWidth: 118, alignment: .leading)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            Image(snapshot.equippedSkinAssetName ?? "mascot-profile")
                .resizable()
                .scaledToFit()
                .frame(width: 74, height: 74)
                .padding(.top, -6)
                .padding(.trailing, -10)
        }
        .widgetURL(DeepLink.profile.url)
        .containerBackground(for: .widget) {
            LumiWidgetGradient.deep
        }
    }
}

struct LumiProfileWidget: Widget {
    let kind = "LumiProfileWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProfileProvider()) { entry in
            LumiProfileWidgetView(snapshot: entry.snapshot)
        }
        .configurationDisplayName("Луми — профиль коротко")
        .description("Уровень, люмены и серия дней в одном взгляде.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    LumiProfileWidget()
} timeline: {
    ProfileEntry(date: .now, snapshot: .sample)
}
