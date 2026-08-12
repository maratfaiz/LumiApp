import SwiftUI

/// Техника «Самообъятие» (self-compassion touch, Neff): 60 секунд тёплого
/// физического жеста с короткой фразой поддержки. Без наград и счётчиков —
/// это практика, а не задание.
struct SelfEmbraceView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var secondsLeft = 60
    @State private var isRunning = false
    @State private var phraseIndex = 0
    @State private var isFinished = false

    private let duration = 60

    /// Фразы намеренно мягкие и без обещаний «всё будет хорошо» —
    /// это признание момента, а не позитивное мышление.
    private let phrases = [
        "Мне сейчас нелегко — и это нормально.",
        "Я могу побыть рядом с собой.",
        "Я отношусь к себе так же тепло, как к другу.",
        "Мне можно бережно к себе.",
    ]

    var body: some View {
        LumiScreen(stars: StarPresets.plan) {
            VStack(spacing: 18) {
                TechniqueHeader(
                    title: "Самообъятие",
                    subtitle: isFinished
                        ? "Минута прошла. Заметь, что изменилось в теле."
                        : "Обними себя за плечи или положи ладонь на грудь — и просто побудь так минуту.",
                    mascotAsset: "mascot-ex6",
                    mascotSize: 130
                )

                LumiProgressRing(
                    progress: Double(duration - secondsLeft) / Double(duration),
                    diameter: 150,
                    lineWidth: 9
                ) {
                    Text("0:\(String(format: "%02d", secondsLeft))")
                        .font(.lumiScreenTitle(34))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                }

                Text("Если прикосновение к себе сейчас неприятно — просто сиди спокойно и слушай фразы. Практика работает и так.")
                    .font(.lumi(11, weight: .semibold))
                    .foregroundStyle(LumiColor.textDim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(phrases[phraseIndex % phrases.count])
                    .font(.lumi(14, weight: .heavy))
                    .foregroundStyle(LumiColor.textBright)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .lumiAccentCard(LumiColor.purple1)

                Spacer(minLength: 8)

                if isFinished {
                    PrimaryButton(title: "Готово") { dismiss() }
                    TextLinkButton(title: "Ещё раз") { reset() }
                } else {
                    PrimaryButton(
                        title: isRunning ? "Пауза" : (secondsLeft == duration ? "Начать" : "Продолжить"),
                        systemImage: isRunning ? "pause.fill" : "play.fill"
                    ) {
                        isRunning.toggle()
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: isRunning) {
            guard isRunning else { return }
            while isRunning && secondsLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isRunning else { return }
                secondsLeft -= 1
                if secondsLeft % 15 == 0 { phraseIndex += 1 }
            }
            if secondsLeft == 0 {
                isRunning = false
                isFinished = true
            }
        }
    }

    private func reset() {
        secondsLeft = duration
        phraseIndex = 0
        isFinished = false
        isRunning = true
    }
}

#Preview {
    NavigationStack { SelfEmbraceView() }
        .preferredColorScheme(.dark)
}
