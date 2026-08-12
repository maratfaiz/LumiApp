import SwiftData
import SwiftUI

/// Техника «Дневник эмоций»: назвать чувство, оценить силу, при желании
/// записать, из-за чего. Записи хранятся (`JournalEntry`) и доступны для
/// перечитывания — в этом и смысл покупки.
///
/// Никаких оценок «правильно/неправильно» и никаких напоминаний «ты давно
/// не записывал» — это инструмент, а не обязанность.
struct EmotionDiaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var emotion: JournalEmotion?
    @State private var intensity: Double = 3
    @State private var note = ""
    @State private var justSaved = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 16) {
                TechniqueHeader(
                    title: "Дневник эмоций",
                    subtitle: "Назвать чувство — уже половина работы с ним.",
                    mascotAsset: "mascot-ex1",
                    mascotSize: 110
                )

                SectionLabel(text: "Что чувствуешь сейчас")
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(JournalEmotion.allCases) { value in
                        emotionTile(value)
                    }
                }

                SectionLabel(text: "Насколько сильно")
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Сила")
                            .font(.lumi(12.5, weight: .semibold))
                            .foregroundStyle(LumiColor.textBody)
                        Spacer()
                        Text("\(Int(intensity))/5")
                            .font(.lumi(12, weight: .heavy))
                            .foregroundStyle(LumiColor.purpleLight)
                    }
                    Slider(value: $intensity, in: 1...5, step: 1)
                        .tint(LumiColor.purple1)
                }
                .padding(14)
                .lumiCard(fill: LumiColor.cardFillLight, radius: 14)

                SectionLabel(text: "Из-за чего — если хочется")
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $note)
                        .font(.lumi(13, weight: .semibold))
                        .padding(8)
                        .frame(height: 100)
                        .lumiInputField()
                    if note.isEmpty {
                        Text("Например: разговор на работе…")
                            .font(.lumi(13, weight: .semibold))
                            .foregroundStyle(LumiColor.textDim)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

                PrimaryButton(title: justSaved ? "Записано ✓" : "Записать", isEnabled: emotion != nil) {
                    save()
                }

                if !entries.isEmpty {
                    SectionLabel(text: "Прошлые записи")
                    VStack(spacing: 8) {
                        ForEach(entries.prefix(10)) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func emotionTile(_ value: JournalEmotion) -> some View {
        let isSelected = emotion == value
        return Button {
            emotion = value
            justSaved = false
        } label: {
            VStack(spacing: 5) {
                LumiIcon(name: value.icon, size: 18, fallbackSystemImage: "circle")
                    .foregroundStyle(isSelected ? LumiColor.purpleLight : LumiColor.textBody)
                Text(value.rawValue)
                    .font(.lumi(9.5, weight: isSelected ? .heavy : .semibold))
                    .foregroundStyle(isSelected ? Color.white : LumiColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? LumiColor.purple1.opacity(0.22) : LumiColor.cardFillLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? LumiColor.purple1 : LumiColor.cardBorder, lineWidth: isSelected ? 2 : 1)
        )
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        HStack(spacing: 11) {
            ZStack {
                Circle().fill(LumiColor.purple1.opacity(0.18)).frame(width: 34, height: 34)
                LumiIcon(name: entry.emotion?.icon ?? "icon-smile", size: 15, fallbackSystemImage: "circle")
                    .foregroundStyle(LumiColor.purpleLight)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.emotionRawValue)
                        .font(.lumi(13, weight: .heavy))
                        .foregroundStyle(Color.white)
                    Text("\(entry.intensity)/5")
                        .font(.lumi(11, weight: .bold))
                        .foregroundStyle(LumiColor.purpleLight)
                }
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.lumi(11.5, weight: .semibold))
                        .foregroundStyle(LumiColor.textBody)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(entry.createdAt, format: .dateTime.day().month().hour().minute())
                    .font(.lumi(10, weight: .semibold))
                    .foregroundStyle(LumiColor.textDim)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
    }

    private func save() {
        guard let emotion else { return }
        modelContext.insert(
            JournalEntry(
                emotionRawValue: emotion.rawValue,
                intensity: Int(intensity),
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )

        let target = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()
        target.journalEntryCount += 1

        note = ""
        intensity = 3
        self.emotion = nil
        justSaved = true
    }
}

#Preview {
    NavigationStack { EmotionDiaryView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
