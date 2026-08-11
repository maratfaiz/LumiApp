import Foundation

/// Static lesson content, transcribed verbatim from
/// docs/product/Lumi_Course_Content.docx ("Принято психологом и
/// копирайтером" — approved by the psychologist and copywriter; 19/20
/// lessons passed final review without notes, 2 point-fixes already
/// folded in). Ships with the app; not user state.
struct Lesson: Identifiable, Codable, Hashable {
    let id: String
    let indexInCourse: Int
    let title: String
    let goal: String
    let explanation: String
    let exercisePrompt: String
    let example: String
    /// What completing the exercise gives the user — shown on the
    /// completion screen alongside `mascotMessage`.
    let result: String
    let mascotMessage: String
    var exerciseKind: ExerciseKind = .freeText
}

/// A course is identified by its MVP number, not its position in the list —
/// courses 3, 4, 6–10 exist in the source psychology document but have no
/// content yet and are intentionally absent here (see Lumi_MVP_Scope.docx).
struct Course: Identifiable, Codable, Hashable {
    let id: String
    let number: Int
    let title: String
    let summary: String
    let lessons: [Lesson]
}
