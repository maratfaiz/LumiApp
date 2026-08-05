import Foundation
import Observation

enum BreathingPhase: CaseIterable {
    case inhale, hold, exhale

    var title: String {
        switch self {
        case .inhale: return "Вдох"
        case .hold: return "Задержка"
        case .exhale: return "Выдох"
        }
    }

    /// Seconds at 1× speed — 4-7-8 technique.
    var baseDuration: Double {
        switch self {
        case .inhale: return 4
        case .hold: return 7
        case .exhale: return 8
        }
    }
}

/// F26 — single unified 4-7-8 technique (replaces 3 earlier-described
/// variants per Lumi_Functional_Requirements.docx v2.0).
@Observable
final class BreathingViewModel {
    private(set) var phase: BreathingPhase = .inhale
    private(set) var secondsRemaining = BreathingPhase.inhale.baseDuration
    private(set) var completedCycles = 0
    private(set) var isPlaying = false
    private(set) var rewardGranted = false

    var targetCycles = 4
    var speed: Double = 1.0 {
        didSet { secondsRemaining = phase.baseDuration / speed }
    }

    private var timer: Timer?

    var isSessionComplete: Bool { completedCycles >= targetCycles }

    var progressWithinPhase: Double {
        let duration = phase.baseDuration / speed
        guard duration > 0 else { return 0 }
        return 1 - (secondsRemaining / duration)
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard !isPlaying, !isSessionComplete else { return }
        isPlaying = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        phase = .inhale
        secondsRemaining = phase.baseDuration / speed
        completedCycles = 0
        rewardGranted = false
    }

    func markRewardGranted() {
        rewardGranted = true
    }

    private func tick() {
        secondsRemaining -= 0.1
        guard secondsRemaining <= 0 else { return }
        advancePhase()
    }

    private func advancePhase() {
        switch phase {
        case .inhale:
            phase = .hold
        case .hold:
            phase = .exhale
        case .exhale:
            phase = .inhale
            completedCycles += 1
            if isSessionComplete {
                pause()
            }
        }
        secondsRemaining = phase.baseDuration / speed
    }
}
