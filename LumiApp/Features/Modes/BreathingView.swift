import SwiftData
import SwiftUI

/// F26 — Дыхание. Player: timer, phase indicator, play/pause, repeat
/// (cycle count), speed, technique info. Reward: +15 lumens, no XP,
/// granted once when the target cycle count is reached.
///
/// The breathing orb, control pills and transport row are ported from the
/// design's breathing screen — the orb scales with the phase instead of
/// being a plain progress ring.
struct BreathingView: View {
    @State private var viewModel = BreathingViewModel()
    @State private var showInfo = false
    @State private var reward: PracticeRewardLedger.Outcome = .alreadyRewardedToday

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private static let speeds: [Double] = [0.75, 1.0, 1.25, 1.5]

    var body: some View {
        Group {
            if viewModel.isSessionComplete {
                ModeCompletionView(
                    title: "Дыхание завершено",
                    subtitle: "Ты сделал(а) \(viewModel.completedCycles) \(RussianPlural.form(viewModel.completedCycles, one: "раунд", few: "раунда", many: "раундов")) 4-7-8. Тело и разум немного спокойнее",
                    mascotAsset: "mascot-breathcomplete",
                    reward: reward,
                    action: { dismiss() }
                )
            } else {
                player
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.isSessionComplete) { _, isComplete in
            if isComplete { grantReward() }
        }
        .onDisappear { viewModel.pause() }
    }

    private var player: some View {
        LumiScreen {
            VStack(spacing: 18) {
                Text(viewModel.phase.title)
                    .font(.lumiScreenTitle(28))
                    .foregroundStyle(Color.white)

                orb

                Text("Цикл \(min(viewModel.completedCycles + 1, viewModel.targetCycles)) из \(viewModel.targetCycles)")
                    .font(.lumi(12, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)

                PracticeRewardBadge(practice: .breathing, progress: progress)

                HStack(spacing: 8) {
                    ControlPillButton(
                        icon: "arrow.counterclockwise",
                        label: "Заново",
                        isActive: false,
                        action: viewModel.reset
                    )
                    ControlPillButton(icon: "info.circle", label: "Инфо", isActive: showInfo) {
                        showInfo.toggle()
                    }
                    ControlPillButton(
                        icon: "icon-clock",
                        label: "\(String(format: "%g", viewModel.speed))×",
                        isActive: viewModel.speed != 1
                    ) {
                        cycleSpeed()
                    }
                }

                if showInfo {
                    Text("Вдох на 4 счёта, задержка на 7, выдох на 8. Помогает снизить тревожность и успокоить нервную систему.")
                        .font(.lumi(11.5, weight: .semibold))
                        .foregroundStyle(LumiColor.textBright)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lumiAccentCard(LumiColor.purple1, radius: 14)
                }

                HStack {
                    Spacer()
                    TransportButton(
                        systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill",
                        size: 64,
                        prominent: true,
                        accessibilityTitle: viewModel.isPlaying ? "Пауза" : "Начать"
                    ) {
                        viewModel.togglePlayPause()
                    }
                    Spacer()
                }

                cyclesStepper
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// Scales with the phase: expands on the inhale, holds, contracts on
    /// the exhale — the design's animated breathing orb.
    private var orb: some View {
        let scale = orbScale
        return ZStack {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))
                .foregroundStyle(LumiColor.textBody.opacity(0.25))
                .frame(width: 210, height: 210)
                .scaleEffect(0.82 + scale * 0.18)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xC9BBFF), LumiColor.purple1.opacity(0.9), LumiColor.purple2],
                        center: .center, startRadius: 0, endRadius: 105
                    )
                )
                .frame(width: 210, height: 210)
                .scaleEffect(scale)
            Text("\(Int(viewModel.secondsRemaining.rounded(.up)))")
                .font(.lumiScreenTitle(40))
                .foregroundStyle(Color.white)
                .monospacedDigit()
        }
        .frame(height: 220)
        .animation(.linear(duration: 0.12), value: viewModel.secondsRemaining)
    }

    private var orbScale: Double {
        switch viewModel.phase {
        case .inhale: return 0.62 + 0.38 * viewModel.progressWithinPhase
        case .hold: return 1
        case .exhale: return 1 - 0.38 * viewModel.progressWithinPhase
        }
    }

    private var cyclesStepper: some View {
        HStack {
            Text("Циклов: \(viewModel.targetCycles)")
                .font(.lumi(12.5, weight: .bold))
                .foregroundStyle(LumiColor.textBody)
            Spacer()
            Stepper("", value: Binding(
                get: { viewModel.targetCycles },
                set: { viewModel.targetCycles = $0 }
            ), in: 1...10)
            .labelsHidden()
            .disabled(viewModel.isPlaying)
            .opacity(viewModel.isPlaying ? 0.5 : 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
    }

    private func cycleSpeed() {
        let speeds = Self.speeds
        let index = speeds.firstIndex(of: viewModel.speed) ?? 1
        viewModel.speed = speeds[(index + 1) % speeds.count]
    }

    private func grantReward() {
        guard !viewModel.rewardGranted else { return }
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        reward = PracticeRewardLedger.grantReward(for: .breathing, progress: existing)
        viewModel.markRewardGranted()
        WidgetSync.refresh()
    }
}

#Preview {
    NavigationStack { BreathingView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
