import SwiftData
import SwiftUI

/// F17 — reminders (no anxiety-inducing copy, e.g. never "you're losing your
/// progress"/"you're falling behind" — see Lumi_Acceptance_Criteria.docx),
/// re-access to disclaimer/privacy policy. Opt-in by design (default off):
/// the toggle only requests notification permission when the user turns it
/// on, never on first launch — matches the app's non-forcing tone.
struct SettingsView: View {
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var permissionDenied = false

    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? 19
                reminderMinute = components.minute ?? 0
                rescheduleIfEnabled()
            }
        )
    }

    var body: some View {
        List {
            Section("Уведомления") {
                Toggle("Напоминания и достижения", isOn: Binding(
                    get: { remindersEnabled },
                    set: { setRemindersEnabled($0) }
                ))
                if remindersEnabled {
                    DatePicker("Время напоминания об уроке", selection: reminderTime, displayedComponents: .hourAndMinute)
                }
                if permissionDenied {
                    Text("Уведомления выключены в настройках iOS. Включи их в Настройках устройства → Луми → Уведомления.")
                        .font(.lumiCaption)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                NavigationLink("Дисклеймер") { DisclaimerView(onAcknowledge: {}) }
                NavigationLink("Политика конфиденциальности") {
                    Text("TODO: текст privacy policy — см. Lumi_MVP_Scope.docx (готовность: текст не готов).")
                        .padding()
                }
            }
        }
        .navigationTitle("Настройки")
    }

    private func setRemindersEnabled(_ enabled: Bool) {
        if enabled {
            NotificationScheduler.requestAuthorizationIfNeeded { granted in
                remindersEnabled = granted
                permissionDenied = !granted
                if granted {
                    rescheduleIfEnabled()
                }
            }
        } else {
            remindersEnabled = false
            NotificationScheduler.cancelAll()
        }
    }

    private func rescheduleIfEnabled() {
        guard remindersEnabled else { return }
        NotificationScheduler.reschedule(hour: reminderHour, minute: reminderMinute, lastActiveDate: progress?.lastActiveDate)
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
