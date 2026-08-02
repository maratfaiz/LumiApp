import SwiftData
import SwiftUI

/// F10 — mascot, current lesson card, streak indicator, course progress.
struct HomeView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    MascotView(state: .neutral)
                        .frame(width: 120, height: 120)

                    if let progress {
                        HStack(spacing: 16) {
                            Label("\(progress.currentStreakDays) дней подряд", systemImage: "flame")
                            Label("\(progress.streakFreezesAvailable) заморозки", systemImage: "snowflake")
                        }
                        .font(.lumiCaption)
                        .foregroundStyle(.secondary)
                    }

                    TodayPracticesView()

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle("Луми")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
