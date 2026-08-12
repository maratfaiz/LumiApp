import SwiftUI

/// Welcome+Sign in with Apple (F1+F2, merged and mandatory) → Disclaimer
/// (cannot be skipped) → 4 questions (F3) → plan builder → personal plan
/// reveal (F4). Total time budget: under 2 minutes end-to-end
/// (Lumi_Acceptance_Criteria.docx).
struct OnboardingFlowView: View {
    @State private var viewModel = OnboardingViewModel()
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            LumiBackground()

            switch viewModel.step {
            case .welcome:
                WelcomeView(viewModel: viewModel, onContinue: viewModel.advance)
            case .name:
                NameStepView(viewModel: viewModel, onContinue: viewModel.advance)
            case .disclaimer:
                DisclaimerView(onAcknowledge: viewModel.advance)
            case .questions:
                OnboardingQuestionsView(viewModel: viewModel)
            case .planLoading:
                OnboardingPlanLoadingView(onFinished: viewModel.advance)
            case .plan:
                OnboardingPlanView(viewModel: viewModel, onFinished: onFinished)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
    }
}

#Preview {
    OnboardingFlowView(onFinished: {})
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
