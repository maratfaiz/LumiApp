import SwiftData
import SwiftUI
import UserNotifications

private struct NotificationEntry: Identifiable {
    let id: String
    let icon: String
    let text: String
    let date: Date?
}

/// F32 — history of lesson reminders, unlocked achievements, and
/// return-after-miss nudges. Shows real delivered local notifications
/// (NotificationScheduler.swift) merged with a synthesized fallback for
/// achievements unlocked while notifications were off, so the list is
/// never empty just because the user only turned reminders on recently.
///
/// Safety (mandatory per doc): "Серия дней под угрозой — вернитесь
/// сегодня" is a forbidden anxiety-inducing phrasing — never reintroduce
/// it. The only sanctioned return-after-miss copy is below.
struct NotificationsView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var deliveredEntries: [NotificationEntry] = []

    var body: some View {
        Group {
            let entries = combinedEntries()
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
        .task { await loadDelivered() }
    }

    private func loadDelivered() async {
        let notifications: [UNNotification] = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
        deliveredEntries = notifications.map { notification in
            NotificationEntry(
                id: notification.request.identifier,
                icon: icon(forIdentifier: notification.request.identifier),
                text: notification.request.content.body,
                date: notification.date
            )
        }
    }

    private func icon(forIdentifier identifier: String) -> String {
        if identifier.hasPrefix("achievement-") { return "rosette" }
        if identifier == "return-after-miss" { return "moon.stars.fill" }
        return "bell.fill"
    }

    private func combinedEntries() -> [NotificationEntry] {
        guard let progress else { return deliveredEntries }

        var entries = deliveredEntries
        let deliveredAchievementIDs = Set(
            deliveredEntries.map(\.id).filter { $0.hasPrefix("achievement-") }
        )

        for achievement in AchievementCatalog.all
        where achievement.isUnlocked(progress)
            && !deliveredAchievementIDs.contains(where: { $0.hasPrefix("achievement-\(achievement.id)-") }) {
            entries.append(NotificationEntry(
                id: "synthesized-\(achievement.id)",
                icon: "rosette",
                text: "Открыто достижение «\(achievement.title)»",
                date: nil
            ))
        }

        if let lastActive = progress.lastActiveDate,
           deliveredEntries.allSatisfy({ $0.id != "return-after-miss" }) {
            let daysSince = Calendar.current.dateComponents([.day], from: lastActive, to: .now).day ?? 0
            if daysSince >= 1 {
                entries.append(NotificationEntry(
                    id: "synthesized-return-after-miss",
                    icon: "moon.stars.fill",
                    text: "Луми ждёт тебя, когда будешь готов(а) продолжить",
                    date: lastActive
                ))
            }
        }

        return entries.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }
}

#Preview {
    NavigationStack { NotificationsView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
