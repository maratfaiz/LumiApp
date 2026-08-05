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
}

struct MatchingPair: Codable, Hashable, Identifiable {
    /// e.g. "Доброта", "Общая человечность", "Осознанность".
    let category: String
    let phrase: String
    var id: String { category }
}
