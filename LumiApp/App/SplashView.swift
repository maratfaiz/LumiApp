import SwiftUI

/// Launch screen from the design: wordmark, mascot on its glow, and a
/// determinate loading bar. Purely cosmetic — it hands over as soon as the
/// bar fills (or on tap), it never gates real work.
struct SplashView: View {
    let onFinish: () -> Void

    @State private var progress: Double = 0

    private let duration: Double = 1.4

    var body: some View {
        ZStack {
            LumiBackground()
            StarField(stars: StarPresets.splash)

            VStack(spacing: 6) {
                Spacer(minLength: 40)

                Text("Луми")
                    .font(.lumiScreenTitle(44))
                    .foregroundStyle(Color.white)
                Text("Твой путь к уверенности")
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .padding(.bottom, 18)

                LumiMascot(assetName: "mascot-splash", size: 140)
                    .padding(.bottom, 22)

                Text("Загружаем Луми…")
                    .font(.lumi(15, weight: .bold))
                    .foregroundStyle(LumiColor.textBody)
                    .padding(.bottom, 16)

                LumiProgressBar(progress: progress, height: 8)
                    .frame(width: 220)

                Text("\(Int(progress * 100))%")
                    .font(.lumi(12, weight: .semibold))
                    .foregroundStyle(LumiColor.textTertiary)
                    .monospacedDigit()
                    .padding(.top, 8)

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .contentShape(Rectangle())
        .onTapGesture { onFinish() }
        .task {
            // Stepped rather than a single `withAnimation`, so the "%"
            // readout and the bar advance together.
            let steps = 28
            let stepNanoseconds = UInt64(duration / Double(steps) * 1_000_000_000)
            for step in 0...steps {
                progress = Double(step) / Double(steps)
                try? await Task.sleep(nanoseconds: stepNanoseconds)
            }
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
