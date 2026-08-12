import SwiftData
import SwiftUI

/// F16 — level/XP bar, lumens, streak, freezes, achievements, settings entry.
/// Ported from the design's `is.profile` screen.
struct ProfileView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var showCrisis = false

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 12) {
                header
                mascotPanel
                levelCard
                statTiles
                achievementsSection
                navRows
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showCrisis) {
            CrisisSupportView()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Профиль")
                .font(.lumiScreenTitle(26))
                .foregroundStyle(Color.white)
            Spacer()
            HStack(spacing: 14) {
                Button {
                    showCrisis = true
                } label: {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 19))
                        .foregroundStyle(Color(hex: 0xFF9F9F))
                }
                .accessibilityLabel("Кризисные ресурсы")

                NavigationLink(destination: NotificationsView()) {
                    LumiIcon(name: "icon-bell", size: 20, fallbackSystemImage: "bell.fill")
                        .foregroundStyle(LumiColor.textSecondary)
                }
                .accessibilityLabel("Уведомления")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Mascot

    private var mascotPanel: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0x2A1D52), Color(hex: 0x150F30)],
                        center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 180
                    )
                )

            EquippedMascotView(size: 175)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)

            NavigationLink(destination: WardrobeView()) {
                LumiIcon(name: "icon-edit", size: 16, fallbackSystemImage: "pencil")
                    .foregroundStyle(Color.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)
            .padding(14)
            .accessibilityLabel("Изменить образ Луми")
        }
    }

    // MARK: Level

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(progress?.userDisplayName ?? "Луми")
                .font(.lumi(15, weight: .heavy))
                .foregroundStyle(Color.white)
            Text("Уровень \(progress?.level ?? 1)")
                .font(.lumi(11.5, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
            LumiProgressBar(progress: levelProgress)
                .padding(.vertical, 4)
            Text(levelCaption)
                .font(.lumi(10, weight: .semibold))
                .foregroundStyle(LumiColor.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiCard(fill: LumiColor.cardFillLight, border: Color.white.opacity(0.08))
    }

    /// Progress through the current level's XP band.
    private var levelProgress: Double {
        let xp = progress?.xp ?? 0
        let thresholds = GamificationRules.levelThresholds
        guard let nextIndex = thresholds.firstIndex(where: { $0 > xp }) else { return 1 }
        let lower = thresholds[max(nextIndex - 1, 0)]
        let upper = thresholds[nextIndex]
        guard upper > lower else { return 1 }
        return Double(xp - lower) / Double(upper - lower)
    }

    private var levelCaption: String {
        let xp = progress?.xp ?? 0
        guard let next = GamificationRules.levelThresholds.first(where: { $0 > xp }) else {
            return "\(xp) XP · максимальный уровень"
        }
        return "\(xp) / \(next) XP"
    }

    // MARK: Stats

    private var statTiles: some View {
        HStack(spacing: 8) {
            NavigationLink(destination: ShopView()) {
                statTile(icon: "icon-lumen", fallback: "star.fill", value: "\(progress?.lumens ?? 0)", label: "Люменов", color: LumiColor.yellow)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: StreakDetailView()) {
                statTile(icon: "icon-streak", fallback: "flame.fill", value: "\(progress?.currentStreakDays ?? 0)", label: "Серия дней", color: LumiColor.orange1)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: StreakDetailView()) {
                statTile(
                    icon: "icon-freeze",
                    fallback: "snowflake",
                    value: "\(progress?.streakFreezesAvailable ?? 0)/\(GamificationRules.maxStoredStreakFreezes)",
                    label: "Заморозки",
                    color: LumiColor.blueChip
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func statTile(icon: String, fallback: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            LumiIcon(name: icon, size: 17, fallbackSystemImage: fallback).foregroundStyle(color)
            Text(value).font(.lumi(14, weight: .heavy)).foregroundStyle(color)
            Text(label).font(.lumi(10, weight: .semibold)).foregroundStyle(color.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.12)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
    }

    // MARK: Achievements

    private var unlockedCount: Int {
        guard let progress else { return 0 }
        return AchievementCatalog.all.filter { $0.isUnlocked(progress) }.count
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Достижения").font(.lumi(14, weight: .heavy)).foregroundStyle(Color.white)
                Spacer()
                NavigationLink(destination: AchievementsView()) {
                    Text("\(unlockedCount) из \(AchievementCatalog.all.count) · Все →")
                        .font(.lumi(12, weight: .bold))
                        .foregroundStyle(LumiColor.purpleLighter)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                ForEach(AchievementCatalog.all.prefix(4)) { achievement in
                    achievementBadge(achievement)
                }
            }
        }
    }

    private func achievementBadge(_ achievement: Achievement) -> some View {
        let unlocked = progress.map { achievement.isUnlocked($0) } ?? false
        let color = AchievementStyle.color(for: achievement.id)
        return VStack(spacing: 6) {
            Circle()
                .fill(unlocked ? color : LumiColor.cardFillFaint)
                .overlay(
                    Circle().stroke(
                        Color.white.opacity(unlocked ? 0 : 0.12),
                        style: StrokeStyle(lineWidth: 1.5, dash: unlocked ? [] : [3])
                    )
                )
                .frame(width: 52, height: 52)
                .overlay(
                    LumiIcon(
                        name: unlocked ? AchievementStyle.icon(for: achievement.id) : "icon-lock",
                        size: unlocked ? 20 : 17,
                        fallbackSystemImage: unlocked ? "rosette" : "lock.fill"
                    )
                    .foregroundStyle(unlocked ? Color(hex: 0x2A1A00) : LumiColor.textDim)
                )
            Text(achievement.title)
                .font(.lumi(9, weight: .bold))
                .foregroundStyle(unlocked ? color : LumiColor.textFaint)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Navigation rows

    private var navRows: some View {
        VStack(spacing: 8) {
            navRow(icon: "icon-shop", fallback: "bag.fill", title: "Магазин") { ShopView() }
            navRow(icon: "icon-stats", fallback: "chart.bar.fill", title: "Статистика") { StatisticsView() }
            navRow(icon: "icon-journal", fallback: "shippingbox.fill", title: "Инвентарь") { InventoryView() }
            navRow(icon: "icon-settings", fallback: "gearshape.fill", title: "Настройки") { SettingsView() }
        }
    }

    private func navRow<Destination: View>(
        icon: String,
        fallback: String,
        title: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 10) {
                LumiIcon(name: icon, size: 16, fallbackSystemImage: fallback)
                Text(title).font(.lumi(13, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(LumiColor.textBright)
            .padding(12)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 12).fill(LumiColor.cardFillLight))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LumiColor.cardBorder, lineWidth: 1))
    }
}

/// Per-achievement icon/colour, kept out of `AchievementCatalog` so the
/// catalog stays pure content (its conditions are spec'd in
/// Lumi_Functional_Requirements.docx, its look is not).
enum AchievementStyle {
    static func icon(for id: String) -> String {
        switch id {
        case "achievement-first-lesson": return "icon-trophy"
        case "achievement-streak-7": return "icon-streak"
        case "achievement-early-bird": return "icon-sunrise"
        case "achievement-course-complete": return "icon-seal"
        case "achievement-streak-30": return "icon-calendar"
        default: return "icon-trophy"
        }
    }

    static func color(for id: String) -> Color {
        switch id {
        case "achievement-first-lesson": return Color(hex: 0xFFB020)
        case "achievement-streak-7": return Color(hex: 0xFF7A30)
        case "achievement-early-bird": return LumiColor.yellow
        case "achievement-course-complete": return LumiColor.purpleLight
        case "achievement-streak-30": return LumiColor.blueChip
        default: return LumiColor.purple1
        }
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
