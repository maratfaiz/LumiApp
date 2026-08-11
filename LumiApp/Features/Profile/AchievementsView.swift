import SwiftData
import SwiftUI

/// F33 — 5 of the doc's "актуальный список" achievements are implemented;
/// 2 others reference an undefined mechanic and 1 more is unnamed in the
/// source, so they're deliberately left out rather than guessed at (see
/// AchievementCatalog.swift).
struct AchievementsView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }
    @State private var showCourses = false

    var body: some View {
        Group {
            if let progress, !progress.completedLessonIDs.isEmpty {
                List(AchievementCatalog.all) { achievement in
                    row(for: achievement, progress: progress)
                }
                .listStyle(.plain)
            } else {
                EmptyStateView(
                    message: "Пока пусто — здесь появятся ваши достижения, как только вы пройдёте первый урок",
                    actionTitle: "К урокам",
                    action: { showCourses = true }
                )
            }
        }
        .navigationTitle("Достижения")
        .navigationDestination(isPresented: $showCourses) {
            CourseListView()
        }
    }

    @ViewBuilder private func row(for achievement: Achievement, progress: UserProgress) -> some View {
        let unlocked = achievement.isUnlocked(progress)
        HStack(spacing: 12) {
            Image(systemName: unlocked ? "rosette" : "circle.dashed")
                .font(.title2)
                .foregroundStyle(unlocked ? LumiColor.accent : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title).font(.lumiBody.bold())
                Text(achievement.conditionDescription).font(.lumiCaption).foregroundStyle(.secondary)
            }
            Spacer()
            if unlocked {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
        .opacity(unlocked ? 1 : 0.6)
    }
}

#Preview {
    NavigationStack { AchievementsView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
