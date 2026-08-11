import Foundation

/// F8 — the 10 documented exercise mechanics. `Lesson.exercisePrompt`
/// supplies the contextual text for every kind (the question, the critic's
/// thought to transform, the demo intro, the letter starter, ...); this
/// enum only carries the *extra* option/pairing data a kind needs beyond
/// that shared prompt.
enum ExerciseKind: Codable, Hashable {
    case freeText
    case choiceOrCustom(options: [String])
    case factOrJudgment
    case rewriteAsFact
    case defusion
    case letterToFriendThenSelf
    case matching(pairs: [MatchingPair])
    case supportLetter
    case actionAndTime(actionOptions: [String])
    case values(valueOptions: [String])
    /// Rate several areas 1–5 each (e.g. Lesson 0.2's three self-esteem
    /// sources) — richer than a single free-text field for the same
    /// approved exercise instruction.
    case multiSlider(labels: [String])
    /// Write a short answer for each of several labelled parts (e.g.
    /// Lesson 5.2's "what didn't work" / "what it doesn't cancel out") —
    /// same approved instruction, structured instead of one text blob.
    case multiPartReflection(labels: [String])
    /// A 1–5 slider plus one reflection field (e.g. Lesson 0.1: rate your
    /// confidence, then note the situation where it showed up).
    case ratingWithReflection(scaleLabel: String, reflectionLabel: String)
    /// User writes a thought; the UI appends a fixed suffix live (e.g.
    /// Lesson 0.3: "... — это мысль, а не факт") — the reverse of
    /// `.defusion`'s fixed prefix.
    case taggedThought(suffix: String)
    /// Free text plus a time-of-day picker, for exercises about doing
    /// something specific today without a preset list of options.
    case freeTextWithTimePicker(timeLabel: String)
}

struct MatchingPair: Codable, Hashable, Identifiable {
    /// e.g. "Доброта", "Общая человечность", "Осознанность".
    let category: String
    let phrase: String
    var id: String { category }
}
