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
        LumiFixedScreen(stars: StarPresets.welcome) {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 6) {
                    Text("Луми")
                        .font(.lumiScreenTitle(46))
                        .foregroundStyle(Color.white)
                    Text("Каждый день чуть ближе к себе")
                        .font(.lumi(15, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                }

                Spacer()

                LumiMascot(assetName: "mascot-welcome", size: 190)

                Spacer()

                Text("Привет! Я Луми — твоя звёздочка поддержки. Будем расти вместе!")
                    .font(.lumi(14, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .lumiCard(radius: 20)
                    .padding(.top, 10)

                Spacer(minLength: 24)

                VStack(spacing: 16) {
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
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Продолжая, вы соглашаетесь с условиями использования")
                        .font(.lumi(11, weight: .semibold))
                        .foregroundStyle(LumiColor.textFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
            }
        }
    }
}

#Preview {
    WelcomeView(viewModel: OnboardingViewModel(), onContinue: {})
        .preferredColorScheme(.dark)
}
