import SwiftData
import SwiftUI

/// F31 — summary, weekly lesson grid, per-course progress, monthly streak
/// calendar with "completed lesson" / "freeze used" markers.
struct StatisticsView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            if let progress {
                VStack(alignment: .leading, spacing: 28) {
                    summarySection(progress)
                    weeklyGridSection(progress)
                    courseProgressSection(progress)
                    monthlyCalendarSection(progress)
                }
                .padding()
            } else {
                EmptyStateView(message: "Пока пусто — статистика появится после первого урока")
            }
        }
        .navigationTitle("Статистика")
    }

    // MARK: Summary

    private func summarySection(_ progress: UserProgress) -> some View {
        HStack(spacing: 12) {
            statCard(title: "Всего уроков", value: "\(progress.completedLessonIDs.count)")
            statCard(title: "Текущая серия", value: "\(progress.currentStreakDays)")
            statCard(title: "Лучшая серия", value: "\(progress.bestStreakDays)")
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.lumiTitle).foregroundStyle(LumiColor.accent)
            Text(title).font(.lumiCaption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Weekly grid

    private func weeklyGridSection(_ progress: UserProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Эта неделя").font(.lumiHeadline)
            HStack(spacing: 8) {
                ForEach(lastSevenDays(), id: \.self) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(hasActivity(on: day, in: progress) ? LumiColor.accent : LumiColor.border)
                            .frame(width: 28, height: 28)
                        Text(weekdayLabel(day)).font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func lastSevenDays() -> [Date] {
        (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now))
        }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EE"
        return formatter.string(from: date).uppercased()
    }

    private func hasActivity(on day: Date, in progress: UserProgress) -> Bool {
        progress.lessonCompletionDates.contains { calendar.isDate($0, inSameDayAs: day) }
    }

    // MARK: Per-course progress

    private func courseProgressSection(_ progress: UserProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Прогресс по курсам").font(.lumiHeadline)
            ForEach(CourseCatalog.courses) { course in
                let percent = courseCompletionPercent(course, progress: progress)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(course.title).font(.lumiBody)
                        Spacer()
                        Text("\(Int(percent * 100))%").font(.lumiCaption).foregroundStyle(.secondary)
                    }
                    ProgressView(value: percent).tint(LumiColor.accent)
                }
            }
        }
    }

    private func courseCompletionPercent(_ course: Course, progress: UserProgress) -> Double {
        guard !course.lessons.isEmpty else { return 0 }
        let done = course.lessons.filter { progress.completedLessonIDs.contains($0.id) }.count
        return Double(done) / Double(course.lessons.count)
    }

    // MARK: Monthly calendar

    private func monthlyCalendarSection(_ progress: UserProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Календарь серии").font(.lumiHeadline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(daysInCurrentMonth(), id: \.self) { day in
                    dayCell(day, progress: progress)
                }
            }
            HStack(spacing: 16) {
                legendItem(color: LumiColor.accent, label: "Урок пройден")
                legendItem(color: .cyan, label: "Заморозка")
            }
            .padding(.top, 4)
        }
    }

    private func dayCell(_ day: Date, progress: UserProgress) -> some View {
        let completed = hasActivity(on: day, in: progress)
        let frozen = progress.freezeUsedDates.contains { calendar.isDate($0, inSameDayAs: day) }
        return Text("\(calendar.component(.day, from: day))")
            .font(.system(size: 11))
            .frame(maxWidth: .infinity, minHeight: 24)
            .background(
                (completed ? LumiColor.accent : frozen ? Color.cyan : Color.clear)
                    .opacity(completed || frozen ? 0.3 : 0),
                in: RoundedRectangle(cornerRadius: 6)
            )
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
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
        .modelContainer(PersistenceController.makePreviewContainer())
}
