import SwiftUI

/// Top-level switch: splash → first-run onboarding (F1–F4) → main app (F5).
/// See docs/product/Lumi_App_Structure.docx §1–2.
///
/// The whole app is dark-only (the design has no light variant), so the
/// color scheme is pinned here rather than following the system setting.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isSplashVisible = true

    var body: some View {
        ZStack {
            LumiBackground()

            if isSplashVisible {
                SplashView { isSplashVisible = false }
                    .transition(.opacity)
            } else if hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingFlowView(onFinished: { hasCompletedOnboarding = true })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isSplashVisible)
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
        .preferredColorScheme(.dark)
        .tint(LumiColor.purpleLight)
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
