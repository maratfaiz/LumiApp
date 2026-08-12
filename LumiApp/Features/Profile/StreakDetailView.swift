import SwiftData
import SwiftUI

/// The design's "Серия дней" screen — current streak ring, this week's
/// day strip (done / freeze / today / empty) and the freeze balance, all
/// read from real progress instead of the mock-up's fixed values.
struct StreakDetailView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var calendar: Calendar { .current }

    private enum DayState { case done, frozen, today, empty }

    var body: some View {
        LumiScreen(stars: StarPresets.streak) {
            VStack(spacing: 16) {
                Text("Серия дней")
                    .font(.lumiScreenTitle(24))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .center)

                LumiProgressRing(
                    progress: ringProgress,
                    diameter: 132,
                    lineWidth: 8,
                    tint: AnyShapeStyle(LumiGradient.streak),
                    glow: LumiColor.orange1
                ) {
                    VStack(spacing: 2) {
                        LumiIcon(name: "icon-streak", size: 24, fallbackSystemImage: "flame.fill")
                            .foregroundStyle(LumiColor.orange1)
                        Text("\(progress?.currentStreakDays ?? 0)")
                            .font(.lumiScreenTitle(32))
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(maxWidth: .infinity)

                Text(encouragement)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                weekStrip

                freezeCard
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var ringProgress: Double {
        let streak = Double(progress?.currentStreakDays ?? 0)
        guard streak > 0 else { return 0 }
        return min(streak.truncatingRemainder(dividingBy: 7) == 0 ? 1 : streak.truncatingRemainder(dividingBy: 7) / 7, 1)
    }

    private var encouragement: String {
        guard let progress, progress.currentStreakDays > 0 else {
            return "Серия начнётся с первого урока.\nНачни, когда будешь готов(а)."
        }
        if progress.currentStreakDays >= progress.bestStreakDays {
            return "Лучшая серия за всё время!\nЕщё немного — и будет рекорд."
        }
        return "Твой рекорд — \(RussianPlural.days(progress.bestStreakDays)).\nПродолжай в своём темпе."
    }

    // MARK: Week strip

    private var weekStrip: some View {
        HStack(spacing: 6) {
            ForEach(lastSevenDays(), id: \.self) { day in
                let state = state(for: day)
                VStack(spacing: 5) {
                    Text(weekdayLabel(day))
                        .font(.lumi(9, weight: state == .empty ? .bold : .heavy))
                        .foregroundStyle(labelColor(state))
                    RoundedRectangle(cornerRadius: 9)
                        .fill(fill(state))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(
                                    borderColor(state),
                                    style: StrokeStyle(
                                        lineWidth: state == .empty ? 1.5 : 2,
                                        dash: state == .empty ? [3] : []
                                    )
                                )
                        )
                        .overlay { marker(state) }
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    @ViewBuilder
    private func marker(_ state: DayState) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.white)
        case .frozen:
            LumiIcon(name: "icon-freeze", size: 12, fallbackSystemImage: "snowflake")
                .foregroundStyle(LumiColor.blueChip)
        case .today:
            LumiIcon(name: "icon-streak", size: 12, fallbackSystemImage: "flame.fill")
                .foregroundStyle(LumiColor.orange1)
        case .empty:
            EmptyView()
        }
    }

    private func state(for day: Date) -> DayState {
        if progress?.lessonCompletionDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) ?? false {
            return .done
        }
        if progress?.freezeUsedDates.contains(where: { calendar.isDate($0, inSameDayAs: day) }) ?? false {
            return .frozen
        }
        if calendar.isDateInToday(day) {
            return .today
        }
        return .empty
    }

    private func labelColor(_ state: DayState) -> Color {
        switch state {
        case .done, .empty: return LumiColor.textDim
        case .frozen: return LumiColor.blueChip
        case .today: return LumiColor.orange1
        }
    }

    private func fill(_ state: DayState) -> AnyShapeStyle {
        switch state {
        case .done: return AnyShapeStyle(LumiGradient.primary)
        case .frozen: return AnyShapeStyle(LumiColor.blueChip.opacity(0.18))
        case .today: return AnyShapeStyle(LumiColor.orange1.opacity(0.15))
        case .empty: return AnyShapeStyle(LumiColor.cardFillLight)
        }
    }

    private func borderColor(_ state: DayState) -> Color {
        switch state {
        case .done: return .clear
        case .frozen: return LumiColor.blueChip
        case .today: return LumiColor.orange1
        case .empty: return Color.white.opacity(0.18)
        }
    }

    private func lastSevenDays() -> [Date] {
        (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: calendar.startOfDay(for: .now))
        }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter.string(from: date).capitalized
    }

    // MARK: Freezes

    private var freezeCard: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(LumiColor.blueChip.opacity(0.18)).frame(width: 36, height: 36)
                LumiIcon(name: "icon-freeze", size: 18, fallbackSystemImage: "snowflake")
                    .foregroundStyle(LumiColor.blueChip)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Заморозки: \(progress?.streakFreezesAvailable ?? 0)/\(GamificationRules.maxStoredStreakFreezes)")
                    .font(.lumi(13, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text("Сохранят серию, если пропустишь день — применяются сами")
                    .font(.lumi(10.5, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x8FA0C9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .lumiAccentCard(LumiColor.blueChip, radius: 14)
    }
}

#Preview {
    NavigationStack { StreakDetailView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
