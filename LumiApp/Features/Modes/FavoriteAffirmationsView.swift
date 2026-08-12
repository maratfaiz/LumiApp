import SwiftData
import SwiftUI

/// «Мои слова» — избранные аффирмации и свои собственные.
///
/// Раньше сердечко в практике сохранялось в базу и на этом всё
/// заканчивалось: посмотреть отмеченное было негде. Теперь избранное
/// собирается здесь, из него можно составить колоду для практики,
/// подставляется в карточку «Мысль дня» на главной, и сюда же можно
/// дописать свои фразы — обычно самые рабочие слова человек формулирует
/// сам.
struct FavoriteAffirmationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var newText = ""
    @State private var isAdding = false

    private var favorites: [Affirmation] {
        guard let progress else { return [] }
        return AffirmationCatalog.fullDeck(custom: progress.customAffirmations)
            .filter { progress.favoriteAffirmationIDs.contains($0.id) || $0.isCustom }
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 14) {
                VStack(spacing: 8) {
                    Text("Мои слова")
                        .font(.lumiScreenTitle(24))
                        .foregroundStyle(Color.white)
                    Text("Фразы, которые ты отметил(а) в практике, и те, что написал(а) сам(а).")
                        .font(.lumi(12.5, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                PrimaryButton(title: "Добавить свою", systemImage: "plus") { isAdding = true }

                if favorites.isEmpty {
                    Text("Пока пусто. В практике «Аффирмации» нажми на сердечко у фразы, которая откликается — она появится здесь.")
                        .font(.lumi(12, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(Color.white.opacity(0.15))
                        )
                } else {
                    ForEach(favorites) { affirmation in
                        card(affirmation)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Своя аффирмация", isPresented: $isAdding) {
            TextField("Например: я справляюсь в своём темпе", text: $newText)
            Button("Добавить") { addCustom() }
            Button("Отмена", role: .cancel) { newText = "" }
        } message: {
            Text("Короткая фраза в настоящем времени, о себе и без «не».")
        }
    }

    private func card(_ affirmation: Affirmation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            LumiIcon(name: "icon-quote", size: 16, fallbackSystemImage: "quote.opening")
                .foregroundStyle(LumiColor.purple1.opacity(0.6))
            VStack(alignment: .leading, spacing: 4) {
                Text(affirmation.text)
                    .font(.lumi(13.5, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                if affirmation.isCustom {
                    Text("твоя фраза")
                        .font(.lumi(9.5, weight: .bold))
                        .foregroundStyle(LumiColor.purpleLight)
                }
            }
            Spacer(minLength: 0)

            Menu {
                ShareLink(item: affirmation.text) {
                    Label("Поделиться", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    remove(affirmation)
                } label: {
                    Label(affirmation.isCustom ? "Удалить" : "Убрать из избранного", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 14)
    }

    private func addCustom() {
        let text = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        newText = ""
        guard !text.isEmpty else { return }

        let target = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        guard !target.customAffirmations.contains(text) else { return }
        target.customAffirmations.append(text)
        target.favoriteAffirmationIDs.append(AffirmationCatalog.customID(for: text))
        AchievementService.claimUnlocked(for: target)
    }

    private func remove(_ affirmation: Affirmation) {
        guard let progress else { return }
        progress.favoriteAffirmationIDs.removeAll { $0 == affirmation.id }
        if affirmation.isCustom {
            progress.customAffirmations.removeAll { $0 == affirmation.text }
        }
    }
}

#Preview {
    NavigationStack { FavoriteAffirmationsView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
