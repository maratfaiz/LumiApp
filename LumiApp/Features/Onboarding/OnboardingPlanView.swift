import SwiftData
import SwiftUI

/// F4 — personal plan reveal + the 1 free streak freeze grant
/// (Lumi_Gamification_Economy.docx: granted before the user has earned
/// any currency themselves).
struct OnboardingPlanView: View {
    @Environment(\.modelContext) private var modelContext
    var viewModel: OnboardingViewModel
    let onFinished: () -> Void

    private var course: Course? {
        CourseCatalog.courses.first { $0.number == viewModel.recommendedCourseNumber }
    }

    private var firstLesson: Lesson? {
        course?.lessons.first
    }

    var body: some View {
        LumiFixedScreen(stars: StarPresets.celebration) {
            VStack(spacing: 0) {
                LumiMascot(assetName: "mascot-obtrack", size: 200)
                    .padding(.bottom, 18)

                Text("Твой персональный план готов!")
                    .font(.lumiScreenTitle(24))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                Text("Мы нашли курс, который поможет тебе чувствовать себя увереннее и поддержит на этом пути")
                    .font(.lumi(14, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 22)

                planRow(
                    icon: "star.fill",
                    iconTint: LumiColor.purpleLight,
                    iconBackground: LumiColor.purple1.opacity(0.25),
                    caption: "Стартовый курс",
                    title: "\(course?.title ?? "") · \(RussianPlural.lessons(course?.lessons.count ?? 0))"
                )
                .padding(.bottom, 12)

                planRow(
                    icon: "checkmark",
                    iconTint: LumiColor.textBody,
                    iconBackground: Color.white.opacity(0.08),
                    caption: "Твой первый урок",
                    title: firstLesson?.title ?? ""
                )
                .padding(.bottom, 16)

                HStack(spacing: 6) {
                    LumiIcon(name: "icon-freeze", size: 14, fallbackSystemImage: "snowflake")
                    Text("+" + RussianPlural.freezes(GamificationRules.freeFreezeOnOnboardingComplete) + " дня")
                }
                .font(.lumi(13, weight: .bold))
                .foregroundStyle(LumiColor.blueChip)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(LumiColor.blueStrong.opacity(0.15)))
                .overlay(Capsule().stroke(LumiColor.blueStrong.opacity(0.3), lineWidth: 1))

                Spacer(minLength: 16)

                PrimaryButton(title: "Начать первый урок →") {
                    grantOnboardingRewardsAndFinish()
                }
            }
        }
    }

    private func planRow(icon: String, iconTint: Color, iconBackground: Color, caption: String, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(iconBackground).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundStyle(iconTint)
            }
            VStack(alignment: .leading, spacing: 3) {
                SectionLabel(text: caption, size: 10)
                Text(title)
                    .font(.lumi(15, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .lumiCard()
    }

    private func grantOnboardingRewardsAndFinish() {
        let progress = UserProgress(
            streakFreezesAvailable: GamificationRules.freeFreezeOnOnboardingComplete,
            currentCourseID: course?.id,
            preferredFormatRawValue: viewModel.preferredFormat?.rawValue,
            userDisplayName: viewModel.userDisplayName
        )
        modelContext.insert(progress)
        WidgetSync.refresh()
        onFinished()
    }
}

#Preview {
    OnboardingPlanView(viewModel: OnboardingViewModel(), onFinished: {})
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
