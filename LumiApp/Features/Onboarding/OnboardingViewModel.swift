import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable {
    /// `planLoading` is the design's "Собирается план" beat between the last
    /// question and the plan reveal — cosmetic, it gates nothing.
    case welcome, disclaimer, questions, planLoading, plan
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

    /// Asset-catalog icon from the design's onboarding screen 2/4.
    var icon: String {
        switch self {
        case .selfCriticism: return "icon-critic-voice"
        case .boundaries: return "icon-clock"
        case .notGoodEnough: return "icon-heart-outline"
        case .anxietyStress: return "icon-anxiety"
        case .other: return "icon-question"
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

    /// Longer label used on the onboarding card, per the design.
    var optionTitle: String {
        switch self {
        case .reading: return "Чтение (тексты)"
        case .audio: return "Аудио (голос, медитация)"
        case .interactive: return "Интерактивные задания"
        }
    }

    var icon: String {
        switch self {
        case .reading: return "icon-book"
        case .audio: return "icon-headphones"
        case .interactive: return "icon-tap"
        }
    }
}

/// Question 4 (goal). Stored as free text on `OnboardingViewModel.goal`;
/// the enum only drives the picker UI, matching the design's 5 options.
enum OnboardingGoal: String, CaseIterable, Identifiable {
    case confidence = "Стать увереннее в себе"
    case lessCritical = "Меньше критиковать себя"
    case anxietyEase = "Легче справляться с тревогой"
    case selfWorth = "Начать ценить себя"
    case other = "Другое"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .confidence: return "icon-target"
        case .lessCritical: return "icon-smile"
        case .anxietyEase: return "icon-bolt"
        case .selfWorth: return "icon-heart-fill"
        case .other: return "icon-question"
        }
    }
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
