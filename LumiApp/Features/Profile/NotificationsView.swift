import SwiftData
import SwiftUI
import UserNotifications

private struct NotificationEntry: Identifiable {
    let id: String
    let icon: String
    let fallbackIcon: String
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
/// it, not even from the design mock-up, which still shows that string.
/// The only sanctioned return-after-miss copy is below.
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
                LumiScreen {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Уведомления")
                            .font(.lumiScreenTitle(24))
                            .foregroundStyle(Color.white)
                            .padding(.bottom, 4)

                        LumiMascot(assetName: "mascot-sleeping", size: 130)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)

                        ForEach(entries) { entry in
                            row(entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDelivered() }
    }

    private func row(_ entry: NotificationEntry) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(LumiColor.purple1.opacity(0.18)).frame(width: 34, height: 34)
                LumiIcon(name: entry.icon, size: 15, fallbackSystemImage: entry.fallbackIcon)
                    .foregroundStyle(LumiColor.purpleLight)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.text)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBright)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = entry.date {
                    Text(date, style: .relative)
                        .font(.lumi(10, weight: .semibold))
                        .foregroundStyle(LumiColor.textDim)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
    }

    private func loadDelivered() async {
        let notifications: [UNNotification] = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
        deliveredEntries = notifications.map { notification in
            let identifier = notification.request.identifier
            return NotificationEntry(
                id: identifier,
                icon: icon(forIdentifier: identifier),
                fallbackIcon: fallbackIcon(forIdentifier: identifier),
                text: notification.request.content.body,
                date: notification.date
            )
        }
    }

    private func icon(forIdentifier identifier: String) -> String {
        if identifier.hasPrefix("achievement-") { return "icon-trophy" }
        if identifier == "return-after-miss" { return "icon-magic" }
        return "icon-bell"
    }

    private func fallbackIcon(forIdentifier identifier: String) -> String {
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
                icon: "icon-trophy",
                fallbackIcon: "rosette",
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
                    icon: "icon-magic",
                    fallbackIcon: "moon.stars.fill",
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
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
