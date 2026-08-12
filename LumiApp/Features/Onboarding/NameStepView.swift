import SwiftUI

/// Шаг «как к тебе обращаться» — отдельно от входа через Apple.
///
/// Apple отдаёт имя только один раз (при самой первой авторизации) и только
/// если пользователь сам согласился им поделиться, поэтому полагаться на
/// него нельзя. Спрашиваем прямо, подставляя то, что пришло от Apple, как
/// заготовку. Имя можно не вводить — тогда Луми обращается без имени, и
/// поменять его можно в любой момент в настройках.
struct NameStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void

    @FocusState private var isFocused: Bool

    private var trimmedName: String {
        viewModel.userDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        LumiFixedScreen(stars: StarPresets.plan) {
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                LumiMascot(assetName: "mascot-ob2", size: 150)

                Text("Как к тебе обращаться?")
                    .font(.lumiScreenTitle(24))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)

                Text("Луми будет звать тебя так. Имя хранится только на твоём устройстве, и его можно поменять в любой момент.")
                    .font(.lumi(12.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 8)

                TextField(
                    "",
                    text: Binding(
                        get: { viewModel.userDisplayName ?? "" },
                        set: { viewModel.userDisplayName = $0 }
                    ),
                    prompt: Text("Имя или как тебе нравится").foregroundStyle(LumiColor.textDim)
                )
                .font(.lumi(16, weight: .bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .padding(16)
                .lumiInputField(radius: 14)
                .padding(.top, 22)

                if !trimmedName.isEmpty {
                    Text("Привет, \(trimmedName)!")
                        .font(.lumi(13, weight: .heavy))
                        .foregroundStyle(LumiColor.purpleLight)
                        .padding(.top, 12)
                        .transition(.opacity)
                }

                Spacer()

                PrimaryButton(title: trimmedName.isEmpty ? "Продолжить без имени" : "Продолжить") {
                    viewModel.userDisplayName = trimmedName.isEmpty ? nil : trimmedName
                    onContinue()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: trimmedName.isEmpty)
        }
        .onAppear { isFocused = true }
    }
}

#Preview {
    NameStepView(viewModel: OnboardingViewModel(), onContinue: {})
        .preferredColorScheme(.dark)
}
