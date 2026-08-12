import SwiftUI

/// The design's "Собирается план" beat between the last question and the
/// plan reveal. Purely presentational — the recommendation itself is
/// already decided by `OnboardingViewModel.recommendedCourseNumber`.
struct OnboardingPlanLoadingView: View {
    let onFinished: () -> Void

    @State private var percent: Double = 0

    private let duration: Double = 2.2

    private var dots: String {
        String(repeating: ".", count: Int(percent / 8) % 3 + 1)
    }

    var body: some View {
        LumiFixedScreen(stars: StarPresets.plan) {
            VStack(spacing: 16) {
                LumiProgressRing(progress: percent / 100, diameter: 196, lineWidth: 12) {
                    Text("\(Int(percent))%")
                        .font(.lumiScreenTitle(46))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                        .shadow(color: LumiColor.purple1.opacity(0.7), radius: 12)
                }

                Text("Собирается план\(dots)")
                    .font(.lumi(12, weight: .bold))
                    .foregroundStyle(LumiColor.textTertiary)
            }
        }
        .task {
            let steps = 44
            let stepNanoseconds = UInt64(duration / Double(steps) * 1_000_000_000)
            for step in 0...steps {
                percent = Double(step) / Double(steps) * 100
                try? await Task.sleep(nanoseconds: stepNanoseconds)
            }
            onFinished()
        }
    }
}

#Preview {
    OnboardingPlanLoadingView(onFinished: {})
        .preferredColorScheme(.dark)
}
