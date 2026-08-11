import SwiftUI

/// F3 — 4 sequential questions, back navigation allowed between them.
struct OnboardingQuestionsView: View {
    var viewModel: OnboardingViewModel
    @State private var page = 0

    var body: some View {
        TabView(selection: $page) {
            confidenceQuestion.tag(0)
            problemAreaQuestion.tag(1)
            formatQuestion.tag(2)
            goalQuestion.tag(3)
        }
        .tabViewStyle(.page)
        .animation(.default, value: page)
    }

    private var confidenceQuestion: some View {
        QuestionScaffold(title: "Как ты оцениваешь свою уверенность сейчас?") {
            Slider(value: Binding(
                get: { Double(viewModel.confidenceRating) },
                set: { viewModel.confidenceRating = Int($0) }
            ), in: 1...5, step: 1)
            Text("\(viewModel.confidenceRating) из 5")
            nextButton { page = 1 }
        }
    }

    private var problemAreaQuestion: some View {
        QuestionScaffold(title: "Что беспокоит сильнее всего?") {
            ForEach(ProblemArea.allCases) { area in
                Button(area.rawValue) {
                    viewModel.problemArea = area
                    page = 2
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var formatQuestion: some View {
        QuestionScaffold(title: "Какой формат тебе удобнее?") {
            ForEach(PreferredFormat.allCases) { format in
                Button(format.rawValue) {
                    viewModel.preferredFormat = format
                    page = 3
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var goalQuestion: some View {
        QuestionScaffold(title: "Какая у тебя цель?") {
            ForEach(["Стать увереннее", "Меньше критиковать себя", "Быть добрее к себе"], id: \.self) { goal in
                Button(goal) {
                    viewModel.goal = goal
                    viewModel.advance()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func nextButton(action: @escaping () -> Void) -> some View {
        Button("Далее", action: action)
            .buttonStyle(.borderedProminent)
            .tint(LumiColor.accent)
    }
}

private struct QuestionScaffold<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.lumiHeadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            content
        }
        .padding()
    }
}

#Preview {
    OnboardingQuestionsView(viewModel: OnboardingViewModel())
}
