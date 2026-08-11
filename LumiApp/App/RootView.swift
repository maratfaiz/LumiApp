import SwiftUI

/// Top-level switch between the first-run onboarding flow (F1–F4) and the
/// main app (F5). See docs/product/Lumi_App_Structure.docx §1–2.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingFlowView(onFinished: { hasCompletedOnboarding = true })
        }
    }
}

#Preview {
    RootView()
}
