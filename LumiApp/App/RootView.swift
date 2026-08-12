import SwiftUI

/// Top-level switch: splash → first-run onboarding (F1–F4) → main app (F5).
/// See docs/product/Lumi_App_Structure.docx §1–2.
///
/// The whole app is dark-only (the design has no light variant), so the
/// color scheme is pinned here rather than following the system setting.
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isSplashVisible = true
    /// Ссылка из виджета, ожидающая обработки.
    @State private var pendingLink: DeepLink?

    var body: some View {
        ZStack {
            LumiBackground()

            if isSplashVisible {
                SplashView { isSplashVisible = false }
                    .transition(.opacity)
            } else if hasCompletedOnboarding {
                MainTabView(pendingLink: pendingLink, onLinkHandled: { pendingLink = nil })
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
        .onOpenURL { url in
            // Возврат из браузера после входа в Google приходит сюда же,
            // что и ссылки виджетов, — сначала отдаём ссылку SDK.
            if GoogleAuth.handle(url) { return }
            guard let link = DeepLink(url: url) else { return }
            // Заставку в этом случае пропускаем: пользователь пришёл с
            // домашнего экрана за конкретным делом.
            isSplashVisible = false
            pendingLink = link
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
