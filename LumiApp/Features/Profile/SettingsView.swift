import SwiftData
import SwiftUI

/// F17 — reminders (no anxiety-inducing copy, e.g. never "you're losing your
/// progress"/"you're falling behind" — see Lumi_Acceptance_Criteria.docx),
/// re-access to disclaimer/privacy policy. Opt-in by design (default off):
/// the toggle only requests notification permission when the user turns it
/// on, never on first launch — matches the app's non-forcing tone.
///
/// Rendered as the design's divider-separated list rather than a system
/// `List`, so it sits on the app background like every other screen.
struct SettingsView: View {
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @State private var permissionDenied = false
    @State private var showCrisis = false
    @State private var showDisclaimer = false
    @State private var showPrivacy = false

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
        LumiScreen {
            VStack(alignment: .leading, spacing: 0) {
                Text("Настройки")
                    .font(.lumiScreenTitle(24))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 10)

                HStack {
                    Text("Напоминания и достижения")
                        .font(.lumi(13, weight: .semibold))
                        .foregroundStyle(LumiColor.textBright)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { remindersEnabled },
                        set: { setRemindersEnabled($0) }
                    ))
                    .labelsHidden()
                    .tint(LumiColor.purple1)
                }
                .padding(.vertical, 12)

                if remindersEnabled {
                    divider
                    HStack {
                        Text("Время напоминания об уроке")
                            .font(.lumi(13, weight: .semibold))
                            .foregroundStyle(LumiColor.textBright)
                        Spacer()
                        DatePicker("", selection: reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.colorScheme, .dark)
                    }
                    .padding(.vertical, 10)
                }

                if permissionDenied {
                    Text("Уведомления выключены в настройках iOS. Включи их в Настройках устройства → Луми → Уведомления.")
                        .font(.lumi(11.5, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .lumiCard(fill: LumiColor.cardFillFaint, radius: 12)
                        .padding(.bottom, 8)
                }

                divider
                settingsRow("Дисклеймер") { showDisclaimer = true }
                divider
                settingsRow("Политика конфиденциальности") { showPrivacy = true }
                divider
                settingsRow("Кризисные ресурсы") { showCrisis = true }
                divider

                Text("Версия 1.0")
                    .font(.lumi(11, weight: .semibold))
                    .foregroundStyle(LumiColor.textDim)
                    .padding(.top, 14)
                Text("Иконки — Phosphor Icons (phosphoricons.com), лицензия MIT, © 2023 Phosphor Icons")
                    .font(.lumi(9.5, weight: .medium))
                    .foregroundStyle(LumiColor.textDim)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCrisis) { CrisisSupportView() }
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerView(onAcknowledge: { showDisclaimer = false })
        }
        .sheet(isPresented: $showPrivacy) {
            privacySheet
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
    }

    private func settingsRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBright)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LumiColor.textDim)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var privacySheet: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 12) {
                Text("Политика конфиденциальности")
                    .font(.lumiScreenTitle(20))
                    .foregroundStyle(Color.white)
                Text("TODO: текст privacy policy — см. Lumi_MVP_Scope.docx (готовность: текст не готов).")
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
