import SwiftUI

/// F8 dispatcher — renders the right mechanic for `lesson.exerciseKind` and
/// keeps `answerText` as a single composed string: empty while the
/// exercise is incomplete, and the full answer once it's ready to submit.
/// LessonPlayerView crisis-checks and submits that string uniformly,
/// regardless of which of the mechanics produced it.
///
/// Every control here uses the design's dark input treatment (translucent
/// fill + hairline border + purple accent) instead of the system defaults.
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
        case .multiSlider(let labels):
            MultiSliderExercise(labels: labels, answerText: $answerText)
        case .multiPartReflection(let labels):
            MultiPartReflectionExercise(labels: labels, answerText: $answerText)
        case .ratingWithReflection(let scaleLabel, let reflectionLabel):
            RatingWithReflectionExercise(scaleLabel: scaleLabel, reflectionLabel: reflectionLabel, answerText: $answerText)
        case .taggedThought(let suffix):
            TaggedThoughtExercise(suffix: suffix, answerText: $answerText)
        case .freeTextWithTimePicker(let timeLabel):
            FreeTextWithTimePickerExercise(timeLabel: timeLabel, answerText: $answerText)
        }
    }
}

// MARK: - Shared building blocks

/// Multi-line answer field on the design's dark input surface.
private struct ExerciseTextEditor: View {
    @Binding var text: String
    var height: CGFloat = 120
    var placeholder: String = "Напиши свой ответ…"

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.lumi(13, weight: .semibold))
                .padding(8)
                .frame(height: height)
                .lumiInputField()
            if text.isEmpty {
                Text(placeholder)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textDim)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct ExerciseFieldLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.lumi(11.5, weight: .bold))
            .foregroundStyle(LumiColor.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Full-width option row, the same visual language as the onboarding
/// questionnaire's `SelectableOptionRow` but without a leading icon.
private struct ExerciseOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.lumi(13, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Color.white : LumiColor.textBody)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if isSelected {
                    ZStack {
                        Circle().fill(LumiColor.purple1).frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? LumiColor.purple1.opacity(0.18) : LumiColor.cardFillLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? LumiColor.purple1 : LumiColor.cardBorder, lineWidth: isSelected ? 2 : 1)
        )
        .buttonStyle(.lumiPlain)
    }
}

/// 1–5 slider with the design's value badge.
private struct ExerciseRatingSlider: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text("\(Int(value))/5")
                    .font(.lumi(12, weight: .heavy))
                    .foregroundStyle(LumiColor.purpleLight)
            }
            Slider(value: $value, in: 1...5, step: 1)
                .tint(LumiColor.purple1)
        }
    }
}

private struct ExerciseTimePicker: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Text(label)
                .font(.lumi(12.5, weight: .semibold))
                .foregroundStyle(LumiColor.textBody)
            Spacer(minLength: 8)
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .environment(\.colorScheme, .dark)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
    }
}

private let hourMinuteFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

// MARK: - 1. Свободный ввод

private struct FreeTextExercise: View {
    @Binding var answerText: String

    var body: some View {
        ExerciseTextEditor(text: $answerText)
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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                ExerciseOptionRow(title: option, isSelected: selected == option && !useCustom) {
                    useCustom = false
                    selected = option
                    answerText = option
                }
            }

            ExerciseOptionRow(title: "Свой вариант", isSelected: useCustom) {
                useCustom = true
                selected = nil
                answerText = customText
            }

            if useCustom {
                ExerciseTextEditor(text: $customText, height: 90, placeholder: "Свой вариант…")
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
        HStack(spacing: 10) {
            choiceButton("Факт")
            choiceButton("Оценка")
        }
    }

    private func choiceButton(_ title: String) -> some View {
        let isSelected = choice == title
        return Button {
            choice = title
            answerText = title
        } label: {
            Text(title)
                .font(.lumi(14, weight: isSelected ? .heavy : .bold))
                .foregroundStyle(isSelected ? Color.white : LumiColor.textBody)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.lumiPlain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? LumiColor.purple1.opacity(0.22) : LumiColor.cardFillLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? LumiColor.purple1 : LumiColor.cardBorder, lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - 4. Переписать как факт

private struct RewriteAsFactExercise: View {
    @Binding var answerText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExerciseFieldLabel(text: "Сформулируй нейтральный факт:")
            ExerciseTextEditor(text: $answerText, height: 100)
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
                .font(.lumi(13, weight: .semibold))
                .italic()
                .foregroundStyle(LumiColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lumiCard(fill: LumiColor.cardFillFaint, radius: 12)

            ExerciseFieldLabel(text: "Теперь попробуй сам(а):")

            VStack(alignment: .leading, spacing: 8) {
                Text(demoPrefix)
                    .font(.lumi(13, weight: .heavy))
                    .foregroundStyle(LumiColor.purpleLight)
                TextField("", text: $completion, axis: .vertical)
                    .font(.lumi(13, weight: .semibold))
                    .padding(12)
                    .lumiInputField()
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
            VStack(alignment: .leading, spacing: 6) {
                ExerciseFieldLabel(text: "Напиши поддержку другу:")
                ExerciseTextEditor(text: $toFriend, height: 90, placeholder: "Что бы ты сказал(а) другу…")
            }
            VStack(alignment: .leading, spacing: 6) {
                ExerciseFieldLabel(text: "Теперь примени те же слова к себе:")
                ExerciseTextEditor(text: $toSelf, height: 90, placeholder: "Те же слова — себе…")
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
        VStack(alignment: .leading, spacing: 10) {
            ForEach(pairs) { pair in
                VStack(alignment: .leading, spacing: 6) {
                    Text(pair.category)
                        .font(.lumi(13, weight: .heavy))
                        .foregroundStyle(Color.white)
                    Menu {
                        Button("—") { assign(nil, to: pair.category) }
                        ForEach(shuffledPhrases, id: \.self) { phrase in
                            Button(phrase) { assign(phrase, to: pair.category) }
                        }
                    } label: {
                        HStack {
                            Text(assignments[pair.category] ?? "Выбрать…")
                                .font(.lumi(12.5, weight: .semibold))
                                .foregroundStyle(assignments[pair.category] == nil ? LumiColor.textDim : LumiColor.textBright)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(LumiColor.textDim)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
                    }
                }
            }
        }
        .onAppear {
            if shuffledPhrases.isEmpty {
                shuffledPhrases = pairs.map(\.phrase).shuffled()
            }
        }
    }

    private func assign(_ phrase: String?, to category: String) {
        assignments[category] = phrase
        recompute()
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
        ExerciseTextEditor(text: $answerText, height: 150, placeholder: "Напиши себе письмо поддержки…")
    }
}

// MARK: - 9. Действие + время

private struct ActionAndTimeExercise: View {
    let actionOptions: [String]
    @Binding var answerText: String

    @State private var selectedAction: String?
    @State private var selectedTime = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(actionOptions, id: \.self) { option in
                ExerciseOptionRow(title: option, isSelected: selectedAction == option) {
                    selectedAction = option
                    recompute()
                }
            }

            ExerciseTimePicker(label: "Время дня", date: $selectedTime)
                .onChange(of: selectedTime) { _, _ in recompute() }
        }
    }

    private func recompute() {
        guard let selectedAction else {
            answerText = ""
            return
        }
        answerText = "\(selectedAction) в \(hourMinuteFormatter.string(from: selectedTime))"
    }
}

// MARK: - 10. Ценности

private struct ValuesExercise: View {
    let valueOptions: [String]
    @Binding var answerText: String

    @State private var selectedValue: String?
    @State private var situation = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(valueOptions, id: \.self) { value in
                ExerciseOptionRow(title: value, isSelected: selectedValue == value) {
                    selectedValue = value
                    recompute()
                }
            }

            ExerciseFieldLabel(text: "В какой ситуации ей стоит следовать?")
            ExerciseTextEditor(text: $situation, height: 90, placeholder: "Опиши ситуацию…")
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

// MARK: - 11. Оцени несколько областей (1–5)

private struct MultiSliderExercise: View {
    let labels: [String]
    @Binding var answerText: String
    @State private var values: [Double]

    init(labels: [String], answerText: Binding<String>) {
        self.labels = labels
        self._answerText = answerText
        self._values = State(initialValue: Array(repeating: 3.0, count: labels.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(labels.indices, id: \.self) { index in
                ExerciseRatingSlider(
                    label: labels[index],
                    value: Binding(
                        get: { values[index] },
                        set: { newValue in
                            values[index] = newValue
                            recompute()
                        }
                    )
                )
            }
        }
        .padding(14)
        .lumiCard(fill: LumiColor.cardFillLight, radius: 14)
        .onAppear { recompute() }
    }

    private func recompute() {
        answerText = zip(labels, values).map { "\($0): \(Int($1))" }.joined(separator: ", ")
    }
}

// MARK: - 12. Ответь по нескольким пунктам

private struct MultiPartReflectionExercise: View {
    let labels: [String]
    @Binding var answerText: String
    @State private var texts: [String]

    init(labels: [String], answerText: Binding<String>) {
        self.labels = labels
        self._answerText = answerText
        self._texts = State(initialValue: Array(repeating: "", count: labels.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(labels.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 6) {
                    ExerciseFieldLabel(text: labels[index])
                    ExerciseTextEditor(
                        text: Binding(
                            get: { texts[index] },
                            set: { newValue in
                                texts[index] = newValue
                                recompute()
                            }
                        ),
                        height: 80
                    )
                }
            }
        }
    }

    private func recompute() {
        let trimmed = texts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !trimmed.contains(where: \.isEmpty) else {
            answerText = ""
            return
        }
        answerText = zip(labels, trimmed).map { "\($0): \($1)" }.joined(separator: " | ")
    }
}

// MARK: - 13. Оценка + размышление

private struct RatingWithReflectionExercise: View {
    let scaleLabel: String
    let reflectionLabel: String
    @Binding var answerText: String

    @State private var rating: Double = 3
    @State private var reflection = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ExerciseRatingSlider(label: scaleLabel, value: $rating)
                .onChange(of: rating) { _, _ in recompute() }

            VStack(alignment: .leading, spacing: 6) {
                ExerciseFieldLabel(text: reflectionLabel)
                ExerciseTextEditor(text: $reflection, height: 90)
                    .onChange(of: reflection) { _, _ in recompute() }
            }
        }
    }

    private func recompute() {
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        answerText = trimmed.isEmpty ? "" : "\(Int(rating))/5. \(trimmed)"
    }
}

// MARK: - 14. Мысль с автодополнением

private struct TaggedThoughtExercise: View {
    let suffix: String
    @Binding var answerText: String
    @State private var thought = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ExerciseTextEditor(text: $thought, height: 90, placeholder: "Напиши свою мысль…")
                .onChange(of: thought) { _, newValue in recompute(newValue) }

            let trimmed = thought.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                Text("«\(trimmed) \(suffix)»")
                    .font(.lumi(12.5, weight: .semibold))
                    .italic()
                    .foregroundStyle(LumiColor.purpleLight)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lumiAccentCard(LumiColor.purple1, radius: 12)
            }
        }
    }

    private func recompute(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        answerText = trimmed.isEmpty ? "" : "\(trimmed) \(suffix)"
    }
}

// MARK: - 15. Действие + время сегодня

private struct FreeTextWithTimePickerExercise: View {
    let timeLabel: String
    @Binding var answerText: String
    @State private var text = ""
    @State private var time = Date.now

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ExerciseTextEditor(text: $text, height: 100)
                .onChange(of: text) { _, _ in recompute() }
            ExerciseTimePicker(label: timeLabel, date: $time)
                .onChange(of: time) { _, _ in recompute() }
        }
    }

    private func recompute() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            answerText = ""
            return
        }
        answerText = "\(trimmed) — сегодня в \(hourMinuteFormatter.string(from: time))"
    }
}
