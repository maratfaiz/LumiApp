import SwiftData
import SwiftUI

/// F27 — swipeable affirmation cards, favorite, optional read-aloud, repeat,
/// speed control. Reward: +15 lumens per session, granted once the user
/// has swiped through every card in the deck.
struct AffirmationsView: View {
    @State private var viewModel = AffirmationsViewModel()
    @State private var dragOffset: CGFloat = 0

    @Environment(\.modelContext) private var modelContext
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        VStack(spacing: 24) {
            Text("\(viewModel.currentIndex + 1) из \(viewModel.cardCount)")
                .font(.lumiCaption)
                .foregroundStyle(.secondary)

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

            HStack(spacing: 32) {
                Button { viewModel.previous() } label: {
                    Image(systemName: "chevron.left.circle.fill").font(.system(size: 36))
                }

                Button { viewModel.speakCurrent() } label: {
                    Image(systemName: viewModel.isSpeaking ? "waveform.circle.fill" : "speaker.wave.2.circle.fill")
                        .font(.system(size: 36))
                }

                Menu {
                    Button("Медленнее") { viewModel.speechRate = max(viewModel.speechRate - 0.1, 0.2) }
                    Button("Быстрее") { viewModel.speechRate = min(viewModel.speechRate + 0.1, 0.6) }
                } label: {
                    Image(systemName: "speedometer").font(.system(size: 28))
                }

                Button { viewModel.next() } label: {
                    Image(systemName: "chevron.right.circle.fill").font(.system(size: 36))
                }
            }
            .tint(LumiColor.accent)

            if viewModel.isSessionComplete {
                completionBanner
            }
        }
        .padding()
        .navigationTitle("Аффирмации")
        .onChange(of: viewModel.isSessionComplete) { _, isComplete in
            if isComplete { grantReward() }
        }
        .onDisappear { viewModel.stopSpeaking() }
    }

    private var card: some View {
        VStack(spacing: 20) {
            MascotView(state: .neutral).frame(width: 80, height: 80)
            Text(viewModel.current.text)
                .font(.lumiHeadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button {
                toggleFavorite()
            } label: {
                Image(systemName: isCurrentFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isCurrentFavorite ? .red : .secondary)
                    .font(.title2)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 20))
    }

    private var completionBanner: some View {
        VStack(spacing: 8) {
            Image("mascot-affirmcomplete").resizable().scaledToFit().frame(width: 70, height: 70)
            Text("Ты прошёл(ла) всю колоду!").font(.lumiBody.bold())
            Text("+15 люменов").font(.lumiCaption).foregroundStyle(LumiColor.accent)
        }
    }

    private var isCurrentFavorite: Bool {
        progress?.favoriteAffirmationIDs.contains(viewModel.current.id) ?? false
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
        existing.lumens += GamificationRules.lumensPerModeSession
        viewModel.markRewardGranted()
    }
}

#Preview {
    NavigationStack { AffirmationsView() }
        .modelContainer(PersistenceController.makePreviewContainer())
}
