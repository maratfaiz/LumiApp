import SwiftData
import SwiftUI

/// F26 — Дыхание. Player: timer, phase indicator, play/pause, repeat
/// (cycle count), speed, technique info. Reward: +15 lumens, no XP,
/// granted once when the target cycle count is reached.
struct BreathingView: View {
    @State private var viewModel = BreathingViewModel()
    @State private var showInfo = false

    @Environment(\.modelContext) private var modelContext
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private static let speeds: [Double] = [0.75, 1.0, 1.25]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            phaseIndicator

            VStack(spacing: 4) {
                Text(viewModel.phase.title).font(.lumiTitle)
                Text("\(Int(viewModel.secondsRemaining.rounded(.up)))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(LumiColor.accent)
                    .monospacedDigit()
            }

            Text("Цикл \(min(viewModel.completedCycles + 1, viewModel.targetCycles)) из \(viewModel.targetCycles)")
                .font(.lumiCaption)
                .foregroundStyle(.secondary)

            Spacer()

            if viewModel.isSessionComplete {
                completionCard
            } else {
                controls
            }
        }
        .padding()
        .navigationTitle("Дыхание")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(isPresented: $showInfo) { infoSheet }
        .onChange(of: viewModel.isSessionComplete) { _, isComplete in
            if isComplete { grantReward() }
        }
        .onDisappear { viewModel.pause() }
    }

    private var phaseIndicator: some View {
        ZStack {
            Circle()
                .stroke(LumiColor.border, lineWidth: 8)
            Circle()
                .trim(from: 0, to: viewModel.progressWithinPhase)
                .stroke(LumiColor.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: viewModel.progressWithinPhase)
            if viewModel.isSessionComplete {
                Image("mascot-breathcomplete").resizable().scaledToFit().frame(width: 90, height: 90)
            } else {
                MascotView(state: .neutral).frame(width: 90, height: 90)
            }
        }
        .frame(width: 200, height: 200)
    }

    private var controls: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise").font(.title2)
                }

                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                .tint(LumiColor.accent)

                Menu {
                    ForEach(Self.speeds, id: \.self) { speed in
                        Button("\(speed, specifier: "%.2g")×") { viewModel.speed = speed }
                    }
                } label: {
                    Image(systemName: "speedometer").font(.title2)
                }
            }

            Stepper(
                "Циклов: \(viewModel.targetCycles)",
                value: Binding(
                    get: { viewModel.targetCycles },
                    set: { viewModel.targetCycles = $0 }
                ),
                in: 1...10
            )
            .disabled(viewModel.isPlaying)
            .padding(.horizontal, 32)
        }
    }

    private var completionCard: some View {
        VStack(spacing: 12) {
            Text("Отлично! Сессия завершена").font(.lumiHeadline)
            Text("+15 люменов").font(.lumiBody).foregroundStyle(LumiColor.accent)
            Button("Ещё раз", action: viewModel.reset)
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
        }
    }

    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Техника 4-7-8").font(.lumiTitle)
            Text("Вдохните на 4 счёта, задержите дыхание на 7 счётов, выдохните на 8 счётов. Эта техника помогает быстро успокоить нервную систему.")
                .font(.lumiBody)
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
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
    NavigationStack { BreathingView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
