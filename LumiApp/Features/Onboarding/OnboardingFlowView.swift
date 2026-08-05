import SwiftUI

/// Welcome+Sign in with Apple (F1+F2, merged and mandatory) → Disclaimer
/// (cannot be skipped) → 4 questions (F3) → personal plan reveal (F4).
/// Total time budget: under 2 minutes end-to-end (Lumi_Acceptance_Criteria.docx).
struct OnboardingFlowView: View {
    @State private var viewModel = OnboardingViewModel()
    let onFinished: () -> Void

    var body: some View {
        Group {
            switch viewModel.step {
            case .welcome:
                WelcomeView(viewModel: viewModel, onContinue: viewModel.advance)
            case .disclaimer:
                DisclaimerView(onAcknowledge: viewModel.advance)
            case .questions:
                OnboardingQuestionsView(viewModel: viewModel)
            case .plan:
                OnboardingPlanView(viewModel: viewModel, onFinished: onFinished)
            }
        }
        .animation(.default, value: viewModel.step)
    }
}
