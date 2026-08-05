import SwiftData
import SwiftUI

private struct NotificationEntry: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let date: Date?
}

/// F32 — history of lesson reminders, unlocked achievements, and
/// return-after-miss nudges. Local push scheduling (F17) isn't wired up
/// yet, so this derives what it can from current state rather than a
/// persisted notification log; "lesson reminder" entries will show once
/// that's built.
///
/// Safety (mandatory per doc): "Серия дней под угрозой — вернитесь
/// сегодня" is a forbidden anxiety-inducing phrasing — never reintroduce
/// it. The only sanctioned return-after-miss copy is below.
struct NotificationsView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        Group {
            let entries = progress.map(makeEntries) ?? []
            if entries.isEmpty {
                EmptyStateView(message: "Пока нет уведомлений")
            } else {
                List(entries) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: entry.icon).foregroundStyle(LumiColor.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.text).font(.lumiBody)
                            if let date = entry.date {
                                Text(date, style: .relative).font(.lumiCaption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Уведомления")
    }

    private func makeEntries(_ progress: UserProgress) -> [NotificationEntry] {
        var entries: [NotificationEntry] = []

        for achievement in AchievementCatalog.all where achievement.isUnlocked(progress) {
            entries.append(NotificationEntry(
                icon: "rosette",
                text: "Открыто достижение «\(achievement.title)»",
                date: nil
            ))
        }

        if let lastActive = progress.lastActiveDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastActive, to: .now).day ?? 0
            if daysSince >= 1 {
                entries.append(NotificationEntry(
                    icon: "moon.stars.fill",
                    text: "Луми ждёт тебя, когда будешь готов(а) продолжить",
                    date: lastActive
                ))
            }
        }

        return entries
    }
}

#Preview {
    NavigationStack { NotificationsView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
