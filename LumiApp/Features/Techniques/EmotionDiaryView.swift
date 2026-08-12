import SwiftData
import SwiftUI

/// Техника «Дневник эмоций» — список записей: поиск, фильтр по эмоции,
/// открытие записи на редактирование, удаление и «поделиться».
///
/// Где это в приложении: главная → «Твои техники», профиль → «Дневник
/// эмоций» (появляется после покупки в магазине) и профиль → Инвентарь.
/// В исходном дизайне экрана дневника не было вообще — он собран под
/// покупку «Дневник эмоций» и достижения «Дневник × 5 / × 20».
struct EmotionDiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var searchText = ""
    @State private var emotionFilter: JournalEmotion?
    @State private var editing: JournalEntry?
    @State private var isCreating = false
    @State private var pendingDeletion: JournalEntry?
    @State private var showCrisisSupport = false
    @State private var showSupportOffer = false

    private let crisisDetector = CrisisDetector()

    private var filtered: [JournalEntry] {
        entries.filter { entry in
            let matchesEmotion = emotionFilter == nil || entry.emotionRawValue == emotionFilter?.rawValue
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesQuery = query.isEmpty
                || entry.note.lowercased().contains(query)
                || entry.emotionRawValue.lowercased().contains(query)
            return matchesEmotion && matchesQuery
        }
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 14) {
                TechniqueHeader(
                    title: "Дневник эмоций",
                    subtitle: "Назвать чувство — уже шаг. Без оценок и правильных ответов.",
                    mascotAsset: "mascot-ex1",
                    mascotSize: entries.isEmpty ? 130 : 90
                )

                PrimaryButton(title: "Новая запись", systemImage: "plus") { isCreating = true }

                if !entries.isEmpty {
                    searchField
                    emotionFilterRow
                    statsRow
                }

                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { entry in
                        entryCard(entry)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isCreating) {
            JournalEditorView(entry: nil) { emotion, intensity, note in
                save(emotion: emotion, intensity: intensity, note: note)
            }
        }
        .sheet(item: $editing) { entry in
            JournalEditorView(entry: entry) { emotion, intensity, note in
                update(entry, emotion: emotion, intensity: intensity, note: note)
            }
        }
        .fullScreenCover(isPresented: $showCrisisSupport) { CrisisSupportView() }
        .confirmationDialog(
            "Похоже, сейчас правда тяжело",
            isPresented: $showSupportOffer,
            titleVisibility: .visible
        ) {
            Button("Показать, где можно получить поддержку") { showCrisisSupport = true }
            Button("Спасибо, продолжу", role: .cancel) {}
        } message: {
            Text("Запись сохранена. Это не диагноз — просто напоминание, что помощь рядом.")
        }
        .confirmationDialog(
            "Удалить запись?",
            isPresented: Binding(get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive) {
                if let pendingDeletion { delete(pendingDeletion) }
                pendingDeletion = nil
            }
            Button("Отмена", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("Запись удалится навсегда — восстановить не получится.")
        }
    }

    // MARK: Поиск и фильтры

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LumiColor.textDim)
            TextField("", text: $searchText, prompt: Text("Поиск по записям").foregroundStyle(LumiColor.textDim))
                .font(.lumi(13, weight: .semibold))
                .foregroundStyle(Color.white)
                .tint(LumiColor.purple1)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LumiColor.textDim)
                }
                .buttonStyle(.lumiPlain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
    }

    private var emotionFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterChip(title: "Все", value: nil)
                ForEach(usedEmotions) { emotion in
                    filterChip(title: emotion.rawValue, value: emotion)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var usedEmotions: [JournalEmotion] {
        let used = Set(entries.map(\.emotionRawValue))
        return JournalEmotion.allCases.filter { used.contains($0.rawValue) }
    }

    private func filterChip(title: String, value: JournalEmotion?) -> some View {
        let isActive = emotionFilter == value
        return Button {
            emotionFilter = value
        } label: {
            Text(title)
                .font(.lumi(11.5, weight: isActive ? .heavy : .bold))
                .foregroundStyle(isActive ? Color.white : LumiColor.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
        }
        .buttonStyle(.lumiPlain)
        .background(Capsule().fill(isActive ? LumiColor.purple1.opacity(0.3) : LumiColor.cardFillLight))
        .overlay(Capsule().stroke(isActive ? LumiColor.purple1.opacity(0.6) : LumiColor.cardBorder, lineWidth: 1))
    }

    /// Мягкая сводка без выводов и оценок: только частота, чтобы человек
    /// сам заметил закономерность.
    private var statsRow: some View {
        let topEmotion = Dictionary(grouping: entries, by: \.emotionRawValue)
            .max { $0.value.count < $1.value.count }

        return HStack(spacing: 8) {
            summaryTile(value: "\(entries.count)", label: "записей")
            if let topEmotion {
                summaryTile(value: topEmotion.key, label: "чаще записываешь")
            }
        }
    }

    private func summaryTile(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.lumi(14, weight: .heavy))
                .foregroundStyle(LumiColor.purpleLight)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.lumi(10, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
    }

    // MARK: Записи

    private func entryCard(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(LumiColor.purple1.opacity(0.18)).frame(width: 34, height: 34)
                    LumiIcon(name: entry.emotion?.icon ?? "icon-smile", size: 15, fallbackSystemImage: "circle")
                        .foregroundStyle(LumiColor.purpleLight)
                }
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(entry.emotionRawValue)
                            .font(.lumi(13, weight: .heavy))
                            .foregroundStyle(Color.white)
                        Text("\(entry.intensity)/5")
                            .font(.lumi(11, weight: .bold))
                            .foregroundStyle(LumiColor.purpleLight)
                    }
                    Text(entry.createdAt, format: .dateTime.day().month().hour().minute())
                        .font(.lumi(10, weight: .semibold))
                        .foregroundStyle(LumiColor.textDim)
                }
                Spacer(minLength: 0)

                Menu {
                    Button {
                        editing = entry
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    ShareLink(item: entry.shareText) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        pendingDeletion = entry
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(LumiColor.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }

            if !entry.note.isEmpty {
                Text(entry.note.lumiMarkdown)
                    .font(.lumi(12.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if entry.updatedAt != nil {
                Text("изменено")
                    .font(.lumi(9.5, weight: .semibold))
                    .foregroundStyle(LumiColor.textDim)
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 14)
        .contentShape(Rectangle())
        .onTapGesture { editing = entry }
    }

    private var emptyState: some View {
        Text(entries.isEmpty
             ? "Здесь появятся твои записи. Можно писать одним словом — этого достаточно."
             : "Ничего не нашлось по этому фильтру.")
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
    }

    // MARK: Действия

    private func save(emotion: JournalEmotion, intensity: Int, note: String) {
        // Дневник — то место, где человек пишет о самом тяжёлом, поэтому
        // здесь работает тот же детектор, что и в уроке.
        switch crisisDetector.evaluate(note) {
        case .crisis: showCrisisSupport = true
        case .concern: showSupportOffer = true
        case .none: break
        }

        modelContext.insert(
            JournalEntry(
                emotionRawValue: emotion.rawValue,
                intensity: intensity,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )

        let target = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        target.journalEntryCount += 1
        target.xp += GamificationRules.xpPerJournalEntry
        LevelSystem.claimPendingRewards(for: target)
        AchievementService.claimUnlocked(for: target)
        WidgetSync.refresh()
    }

    private func update(_ entry: JournalEntry, emotion: JournalEmotion, intensity: Int, note: String) {
        entry.emotionRawValue = emotion.rawValue
        entry.intensity = intensity
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.updatedAt = .now
    }

    private func delete(_ entry: JournalEntry) {
        modelContext.delete(entry)
        if let progress {
            // Счётчик не уходит в минус: достижения считаются по нему.
            progress.journalEntryCount = max(0, progress.journalEntryCount - 1)
        }
    }
}

#Preview {
    NavigationStack { EmotionDiaryView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
