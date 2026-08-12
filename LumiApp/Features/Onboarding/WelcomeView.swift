import GoogleSignInSwift
import SwiftUI

/// F1+F2 merged per Lumi_Functional_Requirements.docx v2.0: «Экран знакомства
/// и регистрация объединены» — единственная точка входа, которую нельзя
/// пропустить.
///
/// Вход через Google (раньше здесь был Sign in with Apple). Настоящей
/// учётной записи всё ещё нет — сервера нет (Stage 5 в
/// Lumi_Project_Handover.docx открыт), поэтому из профиля берётся только
/// имя, чтобы подставить его в следующий шаг. Токены никуда не уходят.
///
/// Если в сборке нет Client ID (`GOOGLE_CLIENT_ID`), экран говорит об этом
/// прямо и даёт пройти дальше — иначе знакомство невозможно было бы
/// открыть вообще, а вместе с ним и всё приложение.
struct WelcomeView: View {
    var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @State private var isSigningIn = false
    @State private var errorMessage: String?

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
                    signInArea

                    Text("Продолжая, вы соглашаетесь с условиями использования")
                        .font(.lumi(11, weight: .semibold))
                        .foregroundStyle(LumiColor.textFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
            }
        }
    }

    @ViewBuilder private var signInArea: some View {
        if GoogleAuth.isConfigured {
            GoogleSignInButton(action: signIn)
                .frame(height: 52)
                .disabled(isSigningIn)
                .opacity(isSigningIn ? 0.6 : 1)

            if let errorMessage {
                Text(errorMessage)
                    .font(.lumi(11.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(spacing: 10) {
                Text("Вход через Google появится, когда в сборку добавят Client ID из Google Cloud.")
                    .font(.lumi(11.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Продолжить без входа", action: onContinue)
            }
        }
    }

    private func signIn() {
        errorMessage = nil
        isSigningIn = true
        Task { @MainActor in
            defer { isSigningIn = false }
            do {
                let account = try await GoogleAuth.signIn()
                if let givenName = account.givenName, !givenName.isEmpty {
                    viewModel.userDisplayName = givenName
                }
                onContinue()
            } catch GoogleAuth.Failure.cancelled {
                // Отмена — это выбор пользователя, а не ошибка: молчим.
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    WelcomeView(viewModel: OnboardingViewModel(), onContinue: {})
        .preferredColorScheme(.dark)
}
