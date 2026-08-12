import SwiftData
import SwiftUI

/// F27 — swipeable affirmation cards, favorite, optional read-aloud,
/// speed control. Reward: +15 lumens per session, granted once the user
/// has swiped through every card in the deck.
///
/// Card, control pills and transport row ported from the design's
/// affirmations screen.
struct AffirmationsView: View {
    @State private var viewModel = AffirmationsViewModel()
    @State private var dragOffset: CGFloat = 0
    @State private var reward: PracticeRewardLedger.Outcome = .alreadyRewardedToday

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private static let speechRates: [Float] = [0.4, 0.5, 0.6]

    var body: some View {
        Group {
            if viewModel.isSessionComplete {
                ModeCompletionView(
                    title: "Сеанс завершён",
                    subtitle: "Ты повторил(а) все \(viewModel.cardCount) аффирмаций. Пусть эти слова останутся с тобой сегодня",
                    mascotAsset: "mascot-affirmcomplete",
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
        .onDisappear { viewModel.stopSpeaking() }
    }

    private var player: some View {
        LumiScreen {
            VStack(spacing: 18) {
                Spacer(minLength: 8)

                PracticeRewardBadge(practice: .affirmations, progress: progress)

                card
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { dragOffset = $0.translation.width }
                            .onEnded { value in
                                if value.translation.width < -60 {
                                    viewModel.next()
                                } else if value.translation.width > 60 {
                                    viewModel.previous()
                                }
                                dragOffset = 0
                            }
                    )
                    .animation(.spring(response: 0.3), value: viewModel.currentIndex)

                HStack(spacing: 8) {
                    ControlPillButton(
                        icon: "speaker.wave.2.fill",
                        label: viewModel.isSpeaking ? "Читаю" : "Прочитать",
                        isActive: viewModel.isSpeaking
                    ) {
                        viewModel.isSpeaking ? viewModel.stopSpeaking() : viewModel.speakCurrent()
                    }
                    ControlPillButton(
                        icon: "icon-heart-fill",
                        label: isCurrentFavorite ? "В избранном" : "В избранное",
                        isActive: isCurrentFavorite,
                        action: toggleFavorite
                    )
                    ControlPillButton(
                        icon: "icon-clock",
                        label: "\(String(format: "%g", speedMultiplier))×",
                        isActive: viewModel.speechRate != 0.5,
                        action: cycleSpeechRate
                    )
                }

                HStack {
                    TransportButton(systemImage: "chevron.left", accessibilityTitle: "Предыдущая") {
                        viewModel.previous()
                    }
                    Spacer()
                    TransportButton(
                        systemImage: viewModel.isSpeaking ? "pause.fill" : "play.fill",
                        size: 64,
                        prominent: true,
                        accessibilityTitle: viewModel.isSpeaking ? "Остановить чтение" : "Прочитать вслух"
                    ) {
                        viewModel.isSpeaking ? viewModel.stopSpeaking() : viewModel.speakCurrent()
                    }
                    Spacer()
                    TransportButton(systemImage: "chevron.right", accessibilityTitle: "Следующая") {
                        viewModel.next()
                    }
                }

                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var card: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [LumiColor.purple1.opacity(0.22), LumiColor.purple2.opacity(0.08)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(LumiColor.purple1.opacity(0.3), lineWidth: 1))

            LumiIcon(name: "icon-quote", size: 28, fallbackSystemImage: "quote.opening")
                .foregroundStyle(LumiColor.purple1.opacity(0.35))
                .padding(16)

            VStack(spacing: 12) {
                Text("«\(viewModel.current.text)»")
                    .font(.lumi(20, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Text("\(viewModel.currentIndex + 1) из \(viewModel.cardCount)")
                    .font(.lumi(11.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)

                if isCurrentFavorite {
                    LumiIcon(name: "icon-heart-fill", size: 16, fallbackSystemImage: "heart.fill")
                        .foregroundStyle(Color(hex: 0xFF7A94))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
        .frame(minHeight: 240)
    }

    private var speedMultiplier: Double {
        Double(viewModel.speechRate / 0.5)
    }

    private var isCurrentFavorite: Bool {
        progress?.favoriteAffirmationIDs.contains(viewModel.current.id) ?? false
    }

    private func cycleSpeechRate() {
        let rates = Self.speechRates
        let index = rates.firstIndex(of: viewModel.speechRate) ?? 1
        viewModel.speechRate = rates[(index + 1) % rates.count]
    }

    private func toggleFavorite() {
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        let id = viewModel.current.id
        if let index = existing.favoriteAffirmationIDs.firstIndex(of: id) {
            existing.favoriteAffirmationIDs.remove(at: index)
        } else {
            existing.favoriteAffirmationIDs.append(id)
        }
    }

    private func grantReward() {
        guard !viewModel.rewardGranted else { return }
        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        reward = PracticeRewardLedger.grantReward(for: .affirmations, progress: existing)
        viewModel.markRewardGranted()
        WidgetSync.refresh()
    }
}

#Preview {
    NavigationStack { AffirmationsView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
