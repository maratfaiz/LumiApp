import SwiftData
import SwiftUI

/// F29 — duration + ambient sound picker (Тишина/Дождь/Океан), session
/// timer. Ambient audio loops a bundled public-domain recording (see
/// docs/legal/Audio_Attributions.md). Reward: +15 lumens, no XP, granted
/// once the timer runs out naturally.
struct MeditationView: View {
    @State private var viewModel = MeditationViewModel()

    @Environment(\.modelContext) private var modelContext
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle().stroke(LumiColor.border, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(LumiColor.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.progress)
                VStack(spacing: 4) {
                    if viewModel.isSessionComplete {
                        Image("mascot-meditationcomplete").resizable().scaledToFit().frame(width: 60, height: 60)
                    } else {
                        MascotView(state: .neutral).frame(width: 60, height: 60)
                    }
                    Text(timeLabel)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 220, height: 220)

            Spacer()

            if viewModel.isSessionComplete {
                completionCard
            } else if viewModel.isRunning {
                Button("Остановить", action: viewModel.stop)
                    .buttonStyle(.bordered)
                    .tint(LumiColor.accent)
            } else {
                setupControls
            }
        }
        .padding()
        .navigationTitle("Медитация")
        .onDisappear { viewModel.stop() }
        .onChange(of: viewModel.isSessionComplete) { _, isComplete in
            if isComplete { grantReward() }
        }
    }

    private var timeLabel: String {
        let minutes = viewModel.secondsRemaining / 60
        let seconds = viewModel.secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var setupControls: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Длительность").font(.lumiCaption).foregroundStyle(.secondary)
                Picker("Длительность", selection: Binding(
                    get: { viewModel.selectedDurationMinutes },
                    set: { viewModel.selectedDurationMinutes = $0 }
                )) {
                    ForEach(MeditationViewModel.availableDurationsMinutes, id: \.self) { minutes in
                        Text("\(minutes) мин").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Звук").font(.lumiCaption).foregroundStyle(.secondary)
                Picker("Звук", selection: Binding(
                    get: { viewModel.selectedAmbient },
                    set: { viewModel.selectedAmbient = $0 }
                )) {
                    ForEach(MeditationAmbient.allCases) { ambient in
                        Text(ambient.rawValue).tag(ambient)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button("Начать", action: viewModel.start)
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
        }
    }

    private var completionCard: some View {
        VStack(spacing: 12) {
            Text("Сессия завершена").font(.lumiHeadline)
            Text("+15 люменов").font(.lumiBody).foregroundStyle(LumiColor.accent)
            Button("Ещё раз", action: viewModel.start)
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
        }
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
    }
}

#Preview {
    NavigationStack { MeditationView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
