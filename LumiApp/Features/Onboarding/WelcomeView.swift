import AuthenticationServices
import SwiftUI

/// F1+F2 merged per Lumi_Functional_Requirements.docx v2.0: "Экран знакомства
/// и регистрация объединены" — single mandatory entry point, Sign in with
/// Apple only (no email/password, no guest mode, cannot be skipped).
/// Real credential handling still needs a backend (Stage 5 architecture,
/// per Lumi_Project_Handover.docx, is still open) — onCompletion just
/// captures the display name (if Apple grants it) and advances.
struct WelcomeView: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            MascotView(state: .neutral)
                .frame(width: 160, height: 160)
            Text("Луми")
                .font(.lumiTitle)
            Text("Каждый день чуть ближе к себе")
                .font(.lumiBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                if case .success(let authorization) = result,
                   let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                   let givenName = credential.fullName?.givenName {
                    viewModel.userDisplayName = givenName
                }
                onContinue()
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 32)
            Text("Продолжая, вы соглашаетесь с условиями использования")
                .font(.lumiCaption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 32)
        }
    }
}

#Preview {
    WelcomeView(viewModel: OnboardingViewModel(), onContinue: {})
}
