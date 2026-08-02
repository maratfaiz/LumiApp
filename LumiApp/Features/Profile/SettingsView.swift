import SwiftUI

/// F17 — reminders (no anxiety-inducing copy, e.g. never "you're losing your
/// progress"/"you're falling behind" — see Lumi_Acceptance_Criteria.docx),
/// re-access to disclaimer/privacy policy.
struct SettingsView: View {
    @AppStorage("remindersEnabled") private var remindersEnabled = true

    var body: some View {
        List {
            Section("Напоминания") {
                Toggle("Мягкие напоминания", isOn: $remindersEnabled)
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
}

#Preview {
    NavigationStack { SettingsView() }
}
