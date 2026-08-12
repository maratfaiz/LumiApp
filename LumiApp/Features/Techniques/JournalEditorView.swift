import SwiftUI

/// Создание и редактирование записи дневника — один экран на оба случая.
/// Форматирование текста (жирный / курсив / список) — через панель над
/// полем, разметка markdown хранится прямо в тексте записи.
struct JournalEditorView: View {
    /// nil — создаём новую запись.
    let entry: JournalEntry?
    let onSave: (JournalEmotion, Int, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editorController = MarkdownEditorController()
    @State private var emotion: JournalEmotion?
    @State private var intensity: Double = 3
    @State private var note = ""
    @State private var showPreview = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var isEditing: Bool { entry != nil }

    var body: some View {
        NavigationStack {
            LumiScreen {
                VStack(alignment: .leading, spacing: 16) {
                    SectionLabel(text: "Что чувствуешь")
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

                    HStack {
                        SectionLabel(text: "Из-за чего — если хочется")
                        Spacer()
                        Button {
                            showPreview.toggle()
                        } label: {
                            Text(showPreview ? "Править" : "Предпросмотр")
                                .font(.lumi(11, weight: .bold))
                                .foregroundStyle(LumiColor.purpleLight)
                        }
                        .buttonStyle(.plain)
                        .opacity(note.isEmpty ? 0 : 1)
                    }

                    if showPreview && !note.isEmpty {
                        Text(note.lumiMarkdown)
                            .font(.lumi(13.5, weight: .semibold))
                            .foregroundStyle(LumiColor.textBody)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
                    } else {
                        VStack(spacing: 8) {
                            MarkdownToolbar(controller: editorController)
                            MarkdownTextEditor(text: $note, controller: editorController)
                                .frame(minHeight: 160)
                                .lumiInputField()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Изменить запись" : "Новая запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Сохранить" : "Записать") {
                        if let emotion {
                            onSave(emotion, Int(intensity), note)
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(emotion == nil)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard let entry else { return }
            emotion = entry.emotion
            intensity = Double(entry.intensity)
            note = entry.note
        }
    }

    private func emotionTile(_ value: JournalEmotion) -> some View {
        let isSelected = emotion == value
        return Button {
            emotion = value
        } label: {
            VStack(spacing: 5) {
                LumiIcon(name: value.icon, size: 18, fallbackSystemImage: "circle")
                    .foregroundStyle(isSelected ? LumiColor.purpleLight : LumiColor.textBody)
                Text(value.rawValue)
                    .font(.lumi(9.5, weight: isSelected ? .heavy : .semibold))
                    .foregroundStyle(isSelected ? Color.white : LumiColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
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
}

#Preview {
    JournalEditorView(entry: nil) { _, _, _ in }
        .preferredColorScheme(.dark)
}
