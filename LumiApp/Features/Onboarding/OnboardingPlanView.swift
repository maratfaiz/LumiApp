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

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            MascotView(state: .achievement)
                .frame(width: 140, height: 140)
            Text("Начнём с курса «\(course?.title ?? "")»")
                .font(.lumiHeadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Начать первый урок") {
                grantOnboardingRewardsAndFinish()
            }
            .buttonStyle(.borderedProminent)
            .tint(LumiColor.accent)
            .padding(.bottom, 32)
        }
    }

    private func grantOnboardingRewardsAndFinish() {
        let progress = UserProgress(
            streakFreezesAvailable: GamificationRules.freeFreezeOnOnboardingComplete,
            currentCourseID: course?.id,
            preferredFormatRawValue: viewModel.preferredFormat?.rawValue
        )
        modelContext.insert(progress)
        onFinished()
    }
}

#Preview {
    OnboardingPlanView(viewModel: OnboardingViewModel(), onFinished: {})
        .modelContainer(PersistenceController.makePreviewContainer())
}
