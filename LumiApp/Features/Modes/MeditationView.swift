import SwiftData
import SwiftUI

/// F29 — duration + ambient sound picker (Тишина/Дождь/Океан), session
/// timer. Ambient audio loops a bundled public-domain recording (see
/// docs/legal/Audio_Attributions.md). Reward: +15 lumens, no XP, granted
/// once the timer runs out naturally.
///
/// Layout ported from the design's "перед сном" screen: big countdown,
/// mascot inside the dashed halo, ambience and duration chip rows.
struct MeditationView: View {
    @State private var viewModel = MeditationViewModel()

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        Group {
            if viewModel.isSessionComplete {
                ModeCompletionView(
                    title: "Медитация завершена",
                    subtitle: "Ты провёл(а) \(viewModel.selectedDurationMinutes) минут в тишине. Дай себе немного этого спокойствия на весь день",
                    mascotAsset: "mascot-meditationcomplete",
                    action: { dismiss() }
                )
            } else {
                player
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.isSessionComplete) { _, isComplete in
            if isComplete { grantReward() }
        }
    }

    private var player: some View {
        LumiScreen {
            VStack(spacing: 14) {
                Text(timeLabel)
                    .font(.lumiScreenTitle(34))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()

                Text(stateLabel)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)

                halo

                ambienceRow
                durationRow

                PrimaryButton(
                    title: viewModel.isRunning ? "Остановить" : "Начать медитацию",
                    systemImage: viewModel.isRunning ? "pause.fill" : "play.fill"
                ) {
                    viewModel.isRunning ? viewModel.stop() : viewModel.start()
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var halo: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [LumiColor.purple1.opacity(0.25), .clear],
                        center: .center, startRadius: 0, endRadius: 125
                    )
                )
                .frame(width: 250, height: 250)
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))
                .foregroundStyle(LumiColor.textBody.opacity(0.25))
                .frame(width: 205, height: 205)
            Circle()
                .trim(from: 0, to: CGFloat(viewModel.progress))
                .stroke(LumiColor.purple1, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 205, height: 205)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progress)
            LumiMascot(assetName: "mascot-meditation", size: 170)
        }
        .frame(height: 250)
    }

    private var ambienceRow: some View {
        HStack(spacing: 8) {
            ForEach(MeditationAmbient.allCases) { ambient in
                let isActive = viewModel.selectedAmbient == ambient
                Button {
                    viewModel.selectedAmbient = ambient
                } label: {
                    HStack(spacing: 5) {
                        LumiIcon(name: ambientIcon(ambient), size: 14, fallbackSystemImage: ambientFallback(ambient))
                        Text(ambient.rawValue)
                    }
                    .font(.lumi(12, weight: isActive ? .heavy : .bold))
                    .foregroundStyle(isActive ? Color.white : LumiColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRunning)
                .opacity(viewModel.isRunning ? 0.5 : 1)
                .background(RoundedRectangle(cornerRadius: 12).fill(isActive ? LumiColor.purple1.opacity(0.25) : LumiColor.cardFillLight))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isActive ? LumiColor.purple1.opacity(0.5) : LumiColor.cardBorder, lineWidth: 1))
            }
        }
    }

    private var durationRow: some View {
        HStack(spacing: 8) {
            ForEach(MeditationViewModel.availableDurationsMinutes, id: \.self) { minutes in
                let isActive = viewModel.selectedDurationMinutes == minutes
                Button {
                    viewModel.selectedDurationMinutes = minutes
                } label: {
                    Text("\(minutes) мин")
                        .font(.lumi(12, weight: isActive ? .heavy : .bold))
                        .foregroundStyle(isActive ? Color.white : LumiColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRunning)
                .opacity(viewModel.isRunning ? 0.5 : 1)
                .background(RoundedRectangle(cornerRadius: 12).fill(isActive ? LumiColor.purple1.opacity(0.25) : LumiColor.cardFillLight))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isActive ? LumiColor.purple1.opacity(0.5) : LumiColor.cardBorder, lineWidth: 1))
            }
        }
    }

    private func ambientIcon(_ ambient: MeditationAmbient) -> String {
        switch ambient {
        case .silence: return "icon-ambience-silence"
        case .rain: return "icon-ambience-rain"
        case .ocean: return "icon-ambience-ocean"
        }
    }

    private func ambientFallback(_ ambient: MeditationAmbient) -> String {
        switch ambient {
        case .silence: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        }
    }

    private var timeLabel: String {
        let seconds = viewModel.isRunning ? viewModel.secondsRemaining : viewModel.selectedDurationMinutes * 60
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private var stateLabel: String {
        guard viewModel.isRunning else { return "Готов(а), когда ты будешь готов(а)" }
        let phrases = ["Дыши спокойно…", "Расслабь плечи…", "Почувствуй тело…", "Отпусти мысли…", "Просто будь здесь…"]
        let elapsed = viewModel.selectedDurationMinutes * 60 - viewModel.secondsRemaining
        return phrases[(elapsed / 12) % phrases.count]
    }

    private func grantReward() {
        guard !viewModel.rewardGranted else { return }
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        existing.lumens += GamificationRules.lumensPerModeSession
        viewModel.markRewardGranted()
        WidgetSync.refresh()
    }
}

#Preview {
    NavigationStack { MeditationView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
