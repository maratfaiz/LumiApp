import SwiftUI

/// F3 — 4 sequential questions, back navigation allowed between them.
/// Layout follows the design's onboarding screens 1/4…4/4: step header,
/// question, mascot pose per step, option cards, gradient CTA.
struct OnboardingQuestionsView: View {
    var viewModel: OnboardingViewModel
    @State private var step = 1

    private let total = 4

    var body: some View {
        LumiFixedScreen {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    if step > 1 {
                        Button {
                            withAnimation { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LumiColor.textBody)
                        }
                        .buttonStyle(.lumiPlain)
                        .accessibilityLabel("Назад")
                    }
                    OnboardingHeader(step: step, total: total)
                }

                switch step {
                case 1: confidenceQuestion
                case 2: problemAreaQuestion
                case 3: formatQuestion
                default: goalQuestion
                }
            }
            .animation(.easeInOut(duration: 0.2), value: step)
        }
    }

    // MARK: 1/4 — confidence

    private var confidenceQuestion: some View {
        VStack(spacing: 0) {
            questionTitle("Как ты сейчас оцениваешь свою уверенность?", subtitle: "Выбери на шкале от 1 до 5", size: 24)

            Spacer()
            LumiMascot(assetName: "mascot-ob1", size: 150)
            Spacer()

            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { number in
                    RatingCircle(number: number, isSelected: viewModel.confidenceRating == number) {
                        withAnimation(.spring(response: 0.3)) { viewModel.confidenceRating = number }
                    }
                }
            }

            HStack {
                Text("Совсем не уверен(а)")
                Spacer()
                Text("Очень уверен(а)")
            }
            .font(.lumi(11, weight: .semibold))
            .foregroundStyle(LumiColor.textTertiary)
            .padding(.top, 10)

            Spacer()
            PrimaryButton(title: "Далее →") { step = 2 }
        }
    }

    // MARK: 2/4 — problem area

    private var problemAreaQuestion: some View {
        VStack(spacing: 0) {
            questionTitle("Что тебя беспокоит сильнее всего?", subtitle: "Выбери то, что ближе", size: 23)

            LumiMascot(assetName: "mascot-ob2", size: 110)
                .padding(.bottom, 14)

            VStack(spacing: 8) {
                ForEach(ProblemArea.allCases) { area in
                    SelectableOptionRow(icon: area.icon, title: area.rawValue, isSelected: viewModel.problemArea == area) {
                        withAnimation { viewModel.problemArea = area }
                    }
                }
            }

            Spacer()
            PrimaryButton(title: "Далее", isEnabled: viewModel.problemArea != nil) { step = 3 }
        }
    }

    // MARK: 3/4 — preferred format

    private var formatQuestion: some View {
        VStack(spacing: 0) {
            questionTitle("Какой формат тебе ближе?", subtitle: "Выбери предпочитаемый", size: 23)

            LumiMascot(assetName: "mascot-ob3", size: 110)
                .padding(.bottom, 20)

            VStack(spacing: 8) {
                ForEach(PreferredFormat.allCases) { format in
                    SelectableOptionRow(icon: format.icon, title: format.optionTitle, isSelected: viewModel.preferredFormat == format) {
                        withAnimation { viewModel.preferredFormat = format }
                    }
                }
            }

            Spacer()
            PrimaryButton(title: "Далее", isEnabled: viewModel.preferredFormat != nil) { step = 4 }
        }
    }

    // MARK: 4/4 — goal

    private var goalQuestion: some View {
        VStack(spacing: 0) {
            questionTitle("Какая у тебя цель на этот путь?", subtitle: "Выбери то, что важно", size: 23)

            LumiMascot(assetName: "mascot-ob4", size: 110)
                .padding(.bottom, 20)

            VStack(spacing: 8) {
                ForEach(OnboardingGoal.allCases) { goal in
                    SelectableOptionRow(icon: goal.icon, title: goal.rawValue, isSelected: viewModel.goal == goal) {
                        withAnimation { viewModel.goal = goal }
                    }
                }
            }

            Spacer()
            PrimaryButton(title: "Готово", isEnabled: viewModel.goal != nil) { viewModel.advance() }
        }
    }

    private func questionTitle(_ title: String, subtitle: String, size: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.lumi(size, weight: .heavy))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.lumi(12, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
        }
        .padding(.top, 18)
        .padding(.bottom, 12)
    }
}

#Preview {
    OnboardingQuestionsView(viewModel: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
