import SwiftUI

/// Welcome → Sign in with Apple (F23) → Disclaimer (F2, cannot be skipped) →
/// 4 questions (F3) → personal plan reveal (F4). Total time budget: under
/// 2 minutes end-to-end (Lumi_Acceptance_Criteria.docx).
///
/// NOTE: F23's exact placement in the flow isn't specified yet in
/// Lumi_Functional_Requirements.docx (only listed in a summary table, no
/// detailed spec section) — placing it right after Welcome is a reasonable
/// default, confirm against the finalized spec before shipping.
struct OnboardingFlowView: View {
    @State private var viewModel = OnboardingViewModel()
    let onFinished: () -> Void

    var body: some View {
        Group {
            switch viewModel.step {
            case .welcome:
                WelcomeView(onContinue: viewModel.advance)
            case .signIn:
                SignInView(onContinue: viewModel.advance)
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
