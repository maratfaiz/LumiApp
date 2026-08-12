import SwiftData
import SwiftUI

/// F31 — summary, weekly lesson bars, per-course progress, monthly streak
/// calendar with "completed lesson" / "freeze used" markers. Layout ported
/// from the design's statistics screen.
struct StatisticsView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var calendar: Calendar { .current }
    private let weekDayLabels = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    var body: some View {
        Group {
            if let progress {
                LumiScreen {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Статистика")
                            .font(.lumiScreenTitle(22))
                            .foregroundStyle(Color.white)

                        summarySection(progress)
                        weeklySection(progress)
                        courseProgressSection(progress)
                        monthlyCalendarSection(progress)
                    }
                }
            } else {
                EmptyStateView(message: "Статистика появится после первого урока")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Summary

    private func summarySection(_ progress: UserProgress) -> some View {
        HStack(spacing: 8) {
            statCard(icon: "icon-journal", fallback: "book.fill", value: "\(progress.completedLessonIDs.count)", label: "уроков всего", color: LumiColor.purpleLight)
            statCard(icon: "icon-streak", fallback: "flame.fill", value: "\(progress.currentStreakDays)", label: "серия сейчас", color: LumiColor.orange1)
            statCard(icon: "icon-trophy", fallback: "star.fill", value: "\(progress.bestStreakDays)", label: "лучшая серия", color: LumiColor.yellow)
        }
    }

    private func statCard(icon: String, fallback: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            LumiIcon(name: icon, size: 16, fallbackSystemImage: fallback).foregroundStyle(color)
            Text(value).font(.lumi(20, weight: .heavy)).foregroundStyle(color)
            Text(label)
                .font(.lumi(10, weight: .bold))
                .foregroundStyle(color.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 14)
    }

    // MARK: Week bars

    private func weeklySection(_ progress: UserProgress) -> some View {
        let days = lastSevenDays()
        let counts = days.map { day in
            progress.lessonCompletionDates.filter { calendar.isDate($0, inSameDayAs: day) }.count
        }
        let maxCount = max(counts.max() ?? 0, 1)
        let activeDays = counts.filter { $0 > 0 }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Уроки за неделю").font(.lumi(12, weight: .bold)).foregroundStyle(LumiColor.textBright)
                Spacer()
                Text("\(activeDays) из 7 дней").font(.lumi(11, weight: .semibold)).foregroundStyle(LumiColor.textSecondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(counts.enumerated()), id: \.offset) { index, count in
                    let isToday = calendar.isDateInToday(days[index])
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isToday ? AnyShapeStyle(LumiGradient.primary) : AnyShapeStyle(LumiColor.purple1.opacity(count > 0 ? 0.45 : 0.15)))
                        .frame(height: max(6, 64 * CGFloat(count) / CGFloat(maxCount)))
                }
            }
            .frame(height: 64, alignment: .bottom)

            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    let isToday = calendar.isDateInToday(day)
                    Text(weekdayLabel(day))
                        .font(.lumi(9, weight: isToday ? .heavy : .regular))
                        .foregroundStyle(isToday ? LumiColor.purpleLight : LumiColor.textFaint2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .lumiCard(fill: LumiColor.cardFillLight)
    }

    // MARK: Per-course progress

    private func courseProgressSection(_ progress: UserProgress) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Прогресс по курсам").font(.lumi(12, weight: .bold)).foregroundStyle(LumiColor.textBright)
            ForEach(CourseCatalog.courses) { course in
                let percent = completionPercent(course, progress: progress)
                let isActive = percent > 0 || course.id == progress.currentCourseID
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Курс \(course.number) · \(course.title)")
                            .font(.lumi(11, weight: .semibold))
                            .foregroundStyle(isActive ? LumiColor.textBody : LumiColor.textDim)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text("\(Int(percent * 100))%")
                            .font(.lumi(11, weight: .bold))
                            .foregroundStyle(isActive ? LumiColor.purple1 : LumiColor.textDim)
                    }
                    LumiProgressBar(progress: percent)
                }
            }
        }
        .padding(14)
        .lumiCard(fill: LumiColor.cardFillLight)
    }

    private func completionPercent(_ course: Course, progress: UserProgress) -> Double {
        guard !course.lessons.isEmpty else { return 0 }
        let done = course.lessons.filter { progress.completedLessonIDs.contains($0.id) }.count
        return Double(done) / Double(course.lessons.count)
    }

    // MARK: Monthly calendar

    private func monthlyCalendarSection(_ progress: UserProgress) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(monthLabel) · календарь серии")
                .font(.lumi(12, weight: .bold))
                .foregroundStyle(LumiColor.textBright)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(weekDayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundStyle(LumiColor.textDim)
                        .frame(maxWidth: .infinity)
                }
                ForEach(Array(0..<leadingBlanks), id: \.self) { _ in
                    Color.clear.frame(height: 30)
                }
                ForEach(daysInCurrentMonth(), id: \.self) { day in
                    dayCell(day, progress: progress)
                }
            }

            HStack(spacing: 12) {
                legend(color: LumiColor.purple1, label: "пройден урок")
                legend(color: LumiColor.blueChip.opacity(0.4), label: "заморозка")
            }
        }
        .padding(14)
        .lumiCard(fill: LumiColor.cardFillLight)
    }

    @ViewBuilder
    private func dayCell(_ day: Date, progress: UserProgress) -> some View {
        let completed = progress.lessonCompletionDates.contains { calendar.isDate($0, inSameDayAs: day) }
        let frozen = progress.freezeUsedDates.contains { calendar.isDate($0, inSameDayAs: day) }
        let isToday = calendar.isDateInToday(day)

        Text("\(calendar.component(.day, from: day))")
            .font(.lumi(10, weight: completed || isToday ? .heavy : .regular))
            .foregroundStyle(completed ? Color.white : (frozen ? LumiColor.blueChip : LumiColor.textDim))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(cellFill(completed: completed, frozen: frozen, isToday: isToday))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isToday ? LumiColor.purple1 : (frozen ? LumiColor.blueChip.opacity(0.5) : .clear),
                        lineWidth: isToday ? 2 : 1
                    )
            )
    }

    private func cellFill(completed: Bool, frozen: Bool, isToday: Bool) -> AnyShapeStyle {
        if completed { return AnyShapeStyle(LumiGradient.primary) }
        if frozen { return AnyShapeStyle(LumiColor.blueChip.opacity(0.2)) }
        if isToday { return AnyShapeStyle(LumiColor.purple1.opacity(0.25)) }
        return AnyShapeStyle(LumiColor.cardFillLight)
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 9)).foregroundStyle(LumiColor.textTertiary)
        }
    }

    // MARK: Dates

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: .now).capitalized
    }

    /// Empty leading cells so the 1st lands under the right weekday
    /// (Monday-first, matching the header row).
    private var leadingBlanks: Int {
        guard let first = daysInCurrentMonth().first else { return 0 }
        let weekday = calendar.component(.weekday, from: first) // 1 = Sunday
        return (weekday + 5) % 7
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

    private func daysInCurrentMonth() -> [Date] {
        let now = Date.now
        guard let range = calendar.range(of: .day, in: .month, for: now),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return []
        }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }
}

#Preview {
    NavigationStack { StatisticsView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
