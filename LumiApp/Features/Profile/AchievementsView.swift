import SwiftData
import SwiftUI

/// F33 — 5 of the doc's "актуальный список" achievements are implemented;
/// the rest reference an undefined mechanic or are unnamed in the source,
/// so they're deliberately left out rather than guessed at (see
/// AchievementCatalog.swift). Split into "открыто" / "впереди" per the
/// design's achievements screen.
struct AchievementsView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var unlocked: [Achievement] {
        guard let progress else { return [] }
        return AchievementCatalog.all.filter { $0.isUnlocked(progress) }
    }

    private var upcoming: [Achievement] {
        guard let progress else { return AchievementCatalog.all }
        return AchievementCatalog.all.filter { !$0.isUnlocked(progress) }
    }

    var body: some View {
        Group {
            if let progress, !progress.completedLessonIDs.isEmpty {
                LumiScreen {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(alignment: .lastTextBaseline) {
                            Text("Достижения")
                                .font(.lumiScreenTitle(22))
                                .foregroundStyle(Color.white)
                            Spacer()
                            Text("\(unlocked.count) из \(AchievementCatalog.all.count)")
                                .font(.lumi(12, weight: .bold))
                                .foregroundStyle(LumiColor.textSecondary)
                        }

                        if !unlocked.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel(text: "Открыто", size: 12)
                                ForEach(unlocked) { unlockedRow($0) }
                            }
                        }

                        if !upcoming.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel(text: "Впереди", size: 12)
                                ForEach(upcoming) { upcomingRow($0) }
                            }
                        }
                    }
                }
            } else {
                EmptyStateView(message: "Здесь появятся ваши достижения, как только вы пройдёте первый урок")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unlockedRow(_ achievement: Achievement) -> some View {
        let color = AchievementStyle.color(for: achievement.id)
        return HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 52, height: 52)
                .overlay(
                    LumiIcon(name: AchievementStyle.icon(for: achievement.id), size: 20, fallbackSystemImage: "rosette")
                        .foregroundStyle(Color(hex: 0x2A1A00))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.lumi(13.5, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text(achievement.conditionDescription)
                    .font(.lumi(10.5, weight: .semibold))
                    .foregroundStyle(color.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                if !achievement.rewardSummary.isEmpty {
                    Text("Получено: \(achievement.rewardSummary)")
                        .font(.lumi(10, weight: .bold))
                        .foregroundStyle(LumiColor.yellow)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiAccentCard(color, radius: 14)
    }

    private func upcomingRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LumiColor.cardFillLight)
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [3]))
                        .foregroundStyle(Color.white.opacity(0.18))
                )
                .overlay(
                    LumiIcon(name: "icon-lock", size: 16, fallbackSystemImage: "lock.fill")
                        .foregroundStyle(LumiColor.textDim)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.lumi(13.5, weight: .heavy))
                    .foregroundStyle(LumiColor.textBright)
                Text(achievement.conditionDescription)
                    .font(.lumi(10.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textFaint2)
                    .fixedSize(horizontal: false, vertical: true)
                if let progress {
                    LumiProgressBar(
                        progress: achievement.progress(progress),
                        height: 4,
                        fill: AnyShapeStyle(LumiColor.textDim)
                    )
                    .padding(.top, 2)
                }
                if !achievement.rewardSummary.isEmpty {
                    Text("Награда: \(achievement.rewardSummary)")
                        .font(.lumi(10, weight: .bold))
                        .foregroundStyle(LumiColor.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiCard(fill: LumiColor.cardFillFaint, border: Color.white.opacity(0.08), radius: 14)
    }
}

#Preview {
    NavigationStack { AchievementsView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
