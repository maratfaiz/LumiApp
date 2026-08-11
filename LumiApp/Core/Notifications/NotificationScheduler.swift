import Foundation
import UserNotifications

/// F32/F17 — local (on-device) notifications only, no backend/remote push:
/// a daily lesson reminder, a single gentle "return after a miss" nudge,
/// and immediate achievement-unlocked alerts. Every string here must stay
/// inside Lumi_App_Structure.docx §7.8's non-punitive tone — no "your
/// streak is at risk", no urgency language. The exact replacement wording
/// mandated by Lumi_Functional_Requirements.docx is used verbatim below.
enum NotificationScheduler {
    private static let reminderIdentifierPrefix = "daily-lesson-reminder-"
    private static let missYouIdentifier = "return-after-miss"
    private static let reminderWindowDays = 14
    private static let missYouDelayDays = 2

    static func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                DispatchQueue.main.async { completion(true) }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion(granted) }
                }
            default:
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Call after any lesson completion and on app foreground. Rebuilds
    /// the rolling window of daily reminders (skipping today if a lesson
    /// was already completed today) and the single "return after miss"
    /// nudge, which always moves forward from the user's last activity.
    static func reschedule(hour: Int, minute: Int, lastActiveDate: Date?, calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let staleIDs = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(reminderIdentifierPrefix) || $0 == missYouIdentifier }
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)

            let today = calendar.startOfDay(for: .now)
            let doneToday = lastActiveDate.map { calendar.isDate($0, inSameDayAs: today) } ?? false

            for offset in 0..<reminderWindowDays {
                if offset == 0 && doneToday { continue }
                guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents(for: day, hour: hour, minute: minute, calendar: calendar),
                    repeats: false
                )
                let content = UNMutableNotificationContent()
                content.title = "Луми"
                content.body = "Не забудьте про сегодняшний урок"
                content.sound = .default
                center.add(UNNotificationRequest(
                    identifier: "\(reminderIdentifierPrefix)\(offset)",
                    content: content,
                    trigger: trigger
                ))
            }

            guard let lastActiveDate else { return }
            let missYouDay = calendar.date(
                byAdding: .day,
                value: missYouDelayDays,
                to: calendar.startOfDay(for: lastActiveDate)
            )
            guard let missYouDay, missYouDay > .now else { return }
            let missYouTrigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents(for: missYouDay, hour: hour, minute: minute, calendar: calendar),
                repeats: false
            )
            let missYouContent = UNMutableNotificationContent()
            missYouContent.title = "Луми"
            missYouContent.body = "Луми ждёт тебя, когда будешь готов(а) продолжить"
            missYouContent.sound = .default
            center.add(UNNotificationRequest(identifier: missYouIdentifier, content: missYouContent, trigger: missYouTrigger))
        }
    }

    /// Fires right away rather than being scheduled ahead, since it
    /// depends on live unlock state at the moment of completion. Callers
    /// must only invoke this for an achievement not already in
    /// `UserProgress.notifiedAchievementIDs`.
    static func notifyAchievementUnlocked(_ achievement: Achievement) {
        let content = UNMutableNotificationContent()
        content.title = "Луми"
        content.body = "Открыто новое достижение 🏅 «\(achievement.title)»"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "achievement-\(achievement.id)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func dateComponents(for day: Date, hour: Int, minute: Int, calendar: Calendar) -> DateComponents {
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        return components
    }
}
