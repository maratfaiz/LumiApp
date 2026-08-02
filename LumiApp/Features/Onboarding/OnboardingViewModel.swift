import Foundation
import Observation

enum OnboardingStep: Int, CaseIterable {
    case welcome, signIn, disclaimer, questions, plan
}

/// Question 2 (problem area) determines the starting course — see
/// docs/product/Lumi_Functional_Requirements.docx §F3–F4.
enum ProblemArea: String, CaseIterable, Identifiable {
    case selfEsteemBasics = "Мне сложно оценивать себя объективно"
    case innerCritic = "Внутренний голос слишком часто меня критикует"
    case selfCompassion = "Мне сложно быть добрым к себе"
    case selfAcceptance = "Мне сложно принимать себя таким/такой, какой я есть"

    var id: String { rawValue }

    /// Maps the chosen problem area to the MVP course number it starts the user on.
    var startingCourseNumber: Int {
        switch self {
        case .selfEsteemBasics: return 0
        case .innerCritic: return 1
        case .selfCompassion: return 2
        case .selfAcceptance: return 5
        }
    }
}

@Observable
final class OnboardingViewModel {
    var step: OnboardingStep = .welcome
    var confidenceRating: Int = 3
    var problemArea: ProblemArea?
    var preferredFormat: String?
    var goal: String?

    var recommendedCourseNumber: Int {
        problemArea?.startingCourseNumber ?? 0
    }

    func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }
}
