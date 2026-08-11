import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome, disclaimer, questions, plan
}

/// Question 2 (problem area) determines the starting course — see
/// docs/product/Lumi_Functional_Requirements.docx v2.0 §F3.
/// Courses 6 (Границы) and 9 (Тревожность/стресс) don't exist in the MVP,
/// so both temporarily fall back to course 0 as a safe start.
enum ProblemArea: String, CaseIterable, Identifiable {
    case selfCriticism = "Сильно критикую себя"
    case boundaries = "Трудно отстаивать свои границы"
    case notGoodEnough = "Чувствую себя недостаточно хорошим(ей)"
    case anxietyStress = "Тревожность и стресс"
    case other = "Другое"

    var id: String { rawValue }

    var startingCourseNumber: Int {
        switch self {
        case .selfCriticism: return 1
        case .notGoodEnough: return 5
        case .boundaries, .anxietyStress, .other: return 0
        }
    }
}

/// Question 3 (format) only controls which mode tiles (Дыхание/Аффирмации/
/// Медитация, F26/F27/F29) get surfaced on Home — lessons stay text-based
/// regardless of this answer.
enum PreferredFormat: String, CaseIterable, Identifiable {
    case reading = "Чтение"
    case audio = "Аудио"
    case interactive = "Интерактивные задания"

    var id: String { rawValue }
}

@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var confidenceRating: Int = 3
    var problemArea: ProblemArea?
    var preferredFormat: PreferredFormat?
    var goal: String?
    /// Captured from Sign in with Apple's .fullName scope, if granted.
    var userDisplayName: String?

    /// Q1 <= 2 always forces course 0, overriding the Q2 answer entirely.
    var recommendedCourseNumber: Int {
        if confidenceRating <= 2 { return 0 }
        return problemArea?.startingCourseNumber ?? 0
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }
}
