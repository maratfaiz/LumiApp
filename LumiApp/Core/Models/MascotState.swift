import Foundation

/// The 4 required mascot states (F15). See docs/product/Lumi_App_Structure.docx §7
/// for where each one is shown, and the mascot prompt doc for visual anti-patterns
/// that must NOT appear in any state's artwork (no confetti/trophies on
/// `.innerCritic`, no exaggerated emotion, no "looking down on the user" poses).
enum MascotState: String, Codable, CaseIterable {
    case neutral
    case success
    case dayMissed
    case innerCritic
    case achievement
}
