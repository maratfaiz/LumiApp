import SwiftUI

/// F8 dispatcher — renders the right mechanic for `lesson.exerciseKind` and
/// keeps `answerText` as a single composed string: empty while the
/// exercise is incomplete, and the full answer once it's ready to submit.
/// LessonPlayerView crisis-checks and submits that string uniformly,
/// regardless of which of the 10 mechanics produced it.
struct ExercisePlayerView: View {
    let kind: ExerciseKind
    let prompt: String
    @Binding var answerText: String

    var body: some View {
        switch kind {
        case .freeText:
            FreeTextExercise(answerText: $answerText)
        case .choiceOrCustom(let options):
            ChoiceOrCustomExercise(options: options, answerText: $answerText)
        case .factOrJudgment:
            FactOrJudgmentExercise(answerText: $answerText)
        case .rewriteAsFact:
            RewriteAsFactExercise(answerText: $answerText)
        case .defusion:
            DefusionExercise(answerText: $answerText)
        case .letterToFriendThenSelf:
            LetterToFriendThenSelfExercise(answerText: $answerText)
        case .matching(let pairs):
            MatchingExercise(pairs: pairs, answerText: $answerText)
        case .supportLetter:
            SupportLetterExercise(answerText: $answerText)
        case .actionAndTime(let actionOptions):
            ActionAndTimeExercise(actionOptions: actionOptions, answerText: $answerText)
        case .values(let valueOptions):
            ValuesExercise(valueOptions: valueOptions, answerText: $answerText)
        }
    }
}

// MARK: - 1. Свободный ввод

private struct FreeTextExercise: View {
    @Binding var answerText: String

    var body: some View {
        TextEditor(text: $answerText)
            .frame(height: 120)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
    }
}

// MARK: - 2. Выбор/свой вариант

private struct ChoiceOrCustomExercise: View {
    let options: [String]
    @Binding var answerText: String

    @State private var selected: String?
    @State private var useCustom = false
    @State private var customText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button {
                    useCustom = false
                    selected = option
                    answerText = option
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        if selected == option && !useCustom {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(LumiColor.accent)
            }

            Button("Свой вариант") {
                useCustom = true
                selected = nil
                answerText = customText
            }
            .buttonStyle(.bordered)

            if useCustom {
                TextEditor(text: $customText)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
                    .onChange(of: customText) { _, newValue in
                        answerText = newValue
                    }
            }
        }
    }
}

// MARK: - 3. Факт или оценка

private struct FactOrJudgmentExercise: View {
    @Binding var answerText: String
    @State private var choice: String?

    var body: some View {
        HStack(spacing: 16) {
            choiceButton("Факт")
            choiceButton("Оценка")
        }
    }

    private func choiceButton(_ title: String) -> some View {
        Button {
            choice = title
            answerText = title
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.bordered)
        .tint(choice == title ? LumiColor.accent : .secondary)
    }
}

// MARK: - 4. Переписать как факт

private struct RewriteAsFactExercise: View {
    @Binding var answerText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сформулируй нейтральный факт:").font(.lumiCaption).foregroundStyle(.secondary)
            TextEditor(text: $answerText)
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
        }
    }
}

// MARK: - 5. Дефузия

private struct DefusionExercise: View {
    @Binding var answerText: String
    @State private var completion = ""

    private let demoPrefix = "Я замечаю мысль, что"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(demoPrefix) я недостаточно хорош(а).")
                .font(.lumiBody)
                .italic()
                .foregroundStyle(.secondary)
            Text("Теперь попробуй сам(а):").font(.lumiCaption).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 4) {
                Text(demoPrefix).font(.lumiBody)
                TextField("...", text: $completion, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
            }
            .onChange(of: completion) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                answerText = trimmed.isEmpty ? "" : "\(demoPrefix) \(trimmed)"
            }
        }
    }
}

// MARK: - 6. Письмо другу → себе

private struct LetterToFriendThenSelfExercise: View {
    @Binding var answerText: String
    @State private var toFriend = ""
    @State private var toSelf = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Напиши поддержку другу:").font(.lumiCaption).foregroundStyle(.secondary)
                TextEditor(text: $toFriend)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Теперь примени те же слова к себе:").font(.lumiCaption).foregroundStyle(.secondary)
                TextEditor(text: $toSelf)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
            }
        }
        .onChange(of: toFriend) { _, _ in recompute() }
        .onChange(of: toSelf) { _, _ in recompute() }
    }

    private func recompute() {
        let friend = toFriend.trimmingCharacters(in: .whitespacesAndNewlines)
        let selfText = toSelf.trimmingCharacters(in: .whitespacesAndNewlines)
        answerText = (friend.isEmpty || selfText.isEmpty) ? "" : "Другу: \(friend)\nСебе: \(selfText)"
    }
}

// MARK: - 7. Сборка соответствий

private struct MatchingExercise: View {
    let pairs: [MatchingPair]
    @Binding var answerText: String

    @State private var assignments: [String: String] = [:] // category -> chosen phrase
    @State private var shuffledPhrases: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(pairs) { pair in
                HStack {
                    Text(pair.category).font(.lumiBody.bold()).frame(width: 140, alignment: .leading)
                    Picker(pair.category, selection: pickerBinding(for: pair.category)) {
                        Text("—").tag("")
                        ForEach(shuffledPhrases, id: \.self) { phrase in
                            Text(phrase).tag(phrase)
                        }
                    }
                    .labelsHidden()
                }
            }
        }
        .onAppear {
            if shuffledPhrases.isEmpty {
                shuffledPhrases = pairs.map(\.phrase).shuffled()
            }
        }
    }

    private func pickerBinding(for category: String) -> Binding<String> {
        Binding(
            get: { assignments[category] ?? "" },
            set: { newValue in
                assignments[category] = newValue.isEmpty ? nil : newValue
                recompute()
            }
        )
    }

    private func recompute() {
        guard assignments.count == pairs.count, !assignments.values.contains(where: \.isEmpty) else {
            answerText = ""
            return
        }
        answerText = pairs.map { "\($0.category) → \(assignments[$0.category] ?? "")" }.joined(separator: "; ")
    }
}

// MARK: - 8. Письмо поддержки

private struct SupportLetterExercise: View {
    @Binding var answerText: String

    var body: some View {
        TextEditor(text: $answerText)
            .frame(height: 140)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
    }
}

// MARK: - 9. Действие + время

private struct ActionAndTimeExercise: View {
    let actionOptions: [String]
    @Binding var answerText: String

    @State private var selectedAction: String?
    @State private var selectedTime = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(actionOptions, id: \.self) { option in
                Button {
                    selectedAction = option
                    recompute()
                } label: {
                    HStack {
                        Text(option)
                        Spacer()
                        if selectedAction == option {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(LumiColor.accent)
            }

            DatePicker("Время дня", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .onChange(of: selectedTime) { _, _ in recompute() }
        }
    }

    private func recompute() {
        guard let selectedAction else {
            answerText = ""
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        answerText = "\(selectedAction) в \(formatter.string(from: selectedTime))"
    }
}

// MARK: - 10. Ценности

private struct ValuesExercise: View {
    let valueOptions: [String]
    @Binding var answerText: String

    @State private var selectedValue: String?
    @State private var situation = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(valueOptions, id: \.self) { value in
                Button {
                    selectedValue = value
                    recompute()
                } label: {
                    HStack {
                        Text(value)
                        Spacer()
                        if selectedValue == value {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .tint(LumiColor.accent)
            }

            Text("В какой ситуации ей стоит следовать?").font(.lumiCaption).foregroundStyle(.secondary)
            TextEditor(text: $situation)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(LumiColor.border))
                .onChange(of: situation) { _, _ in recompute() }
        }
    }

    private func recompute() {
        let trimmedSituation = situation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let selectedValue, !trimmedSituation.isEmpty else {
            answerText = ""
            return
        }
        answerText = "\(selectedValue): \(trimmedSituation)"
    }
}
