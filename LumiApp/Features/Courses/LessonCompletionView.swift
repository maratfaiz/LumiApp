import SwiftData
import SwiftUI

/// F9 — reward + mascot success reaction, shown before the user can move on.
/// Ported from the design's "Отличная работа!" screen, including the
/// separate "Серия начата!" celebration the design shows the very first
/// time a streak starts.
struct LessonCompletionView: View {
    let course: Course
    let lesson: Lesson

    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var showStreakStart = false

    private var isFirstStreakDay: Bool {
        (progress?.currentStreakDays ?? 0) == 1 && (progress?.completedLessonIDs.count ?? 0) <= 1
    }

    var body: some View {
        LumiScreen(stars: StarPresets.celebration) {
            VStack(spacing: 0) {
                Spacer(minLength: 8)

                Text("Отличная работа!")
                    .font(.lumiScreenTitle(28))
                    .foregroundStyle(Color.white)
                    .padding(.bottom, 6)

                Text(subtitle)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 22)

                LumiMascot(assetName: "mascot-lessoncomplete", size: 190, accessibilityTitle: "Луми радуется успеху")
                    .padding(.bottom, 26)

                HStack(spacing: 10) {
                    rewardCard(
                        value: "+\(GamificationRules.xpPerLesson) XP",
                        label: "Опыт",
                        color: LumiColor.green,
                        icon: "star.fill"
                    )
                    rewardCard(
                        value: "+\(GamificationRules.lumensPerLesson)",
                        label: "Люменов",
                        color: LumiColor.yellow,
                        icon: "icon-lumen",
                        valueColor: .white
                    )
                }
                .padding(.bottom, 22)

                if !lesson.result.isEmpty && lesson.result != "TODO" {
                    Text(lesson.result)
                        .font(.lumi(12, weight: .semibold))
                        .foregroundStyle(LumiColor.textBody)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .lumiCard(radius: 14)
                        .padding(.bottom, 20)
                }

                PrimaryButton(title: "Далее") { dismiss() }

                TextLinkButton(title: "Вернуться на главную", color: LumiColor.textTertiary) { dismiss() }

                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if isFirstStreakDay { showStreakStart = true }
        }
        .fullScreenCover(isPresented: $showStreakStart) {
            StreakStartView { showStreakStart = false }
        }
    }

    private var subtitle: String {
        let message = lesson.mascotMessage
        if message.isEmpty || message == "TODO" {
            return "Ты сделал(а) важный шаг к уверенности в себе."
        }
        return message
    }

    private func rewardCard(value: String, label: String, color: Color, icon: String, valueColor: Color? = nil) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.25)).frame(width: 34, height: 34)
                LumiGlyph(name: icon, size: 15).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.lumi(14, weight: .heavy)).foregroundStyle(valueColor ?? color)
                Text(label).font(.lumi(10, weight: .semibold)).foregroundStyle(LumiColor.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(color.opacity(0.14)))
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        LessonCompletionView(course: CourseCatalog.courses[0], lesson: CourseCatalog.courses[0].lessons[0])
    }
    .preferredColorScheme(.dark)
    .modelContainer(PersistenceController.makePreviewContainer())
}
