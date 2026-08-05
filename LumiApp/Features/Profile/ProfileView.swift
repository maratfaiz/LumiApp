import SwiftData
import SwiftUI

/// F16 — level/XP bar, lumens, streak, freezes, achievements, settings entry.
struct ProfileView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        NavigationStack {
            List {
                if let progress {
                    Section {
                        LabeledContent("Уровень", value: "\(progress.level)")
                        LabeledContent("XP", value: "\(progress.xp)")
                        LabeledContent("Люмены", value: "\(progress.lumens)")
                        LabeledContent("Серия дней", value: "\(progress.currentStreakDays)")
                        LabeledContent("Заморозки", value: "\(progress.streakFreezesAvailable)")
                    }
                }

                Section {
                    NavigationLink("Инвентарь") { InventoryView() }
                    NavigationLink("Статистика") { StatisticsView() }
                    NavigationLink("Достижения") { AchievementsView() }
                    NavigationLink("Уведомления") { NotificationsView() }
                }

                Section {
                    NavigationLink("Магазин") { ShopView() }
                    NavigationLink("Настройки") { SettingsView() }
                    NavigationLink("Кризисные ресурсы") { CrisisSupportView() }
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
