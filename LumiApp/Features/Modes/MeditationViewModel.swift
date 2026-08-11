import AVFoundation
import Foundation
import Observation

/// F29 — ambient options. Silence plays nothing; Rain/Ocean loop bundled
/// public-domain recordings (see docs/legal/Audio_Attributions.md).
enum MeditationAmbient: String, CaseIterable, Identifiable {
    case silence = "Тишина"
    case rain = "Дождь"
    case ocean = "Океан"

    var id: String { rawValue }

    var resourceName: String? {
        switch self {
        case .silence: return nil
        case .rain: return "ambient-rain"
        case .ocean: return "ambient-ocean"
        }
    }
}

@Observable
final class MeditationViewModel: NSObject {
    static let availableDurationsMinutes = [3, 5, 10, 15]

    var selectedDurationMinutes = 5
    var selectedAmbient: MeditationAmbient = .silence
    private(set) var isRunning = false
    private(set) var secondsRemaining = 5 * 60
    private(set) var rewardGranted = false

    private var timer: Timer?
    private var player: AVAudioPlayer?

    var isSessionComplete: Bool { !isRunning && secondsRemaining <= 0 }

    var progress: Double {
        let total = Double(selectedDurationMinutes * 60)
        guard total > 0 else { return 0 }
        return 1 - Double(secondsRemaining) / total
    }

    func start() {
        guard !isRunning else { return }
        secondsRemaining = selectedDurationMinutes * 60
        rewardGranted = false
        isRunning = true
        playAmbient()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func markRewardGranted() {
        rewardGranted = true
    }

    private func tick() {
        guard secondsRemaining > 0 else {
            stop()
            return
        }
        secondsRemaining -= 1
        if secondsRemaining <= 0 {
            stop()
        }
    }

    private func playAmbient() {
        guard let name = selectedAmbient.resourceName,
              let url = Bundle.main.url(forResource: name, withExtension: "m4a") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0.6
            newPlayer.play()
            player = newPlayer
        } catch {
            player = nil
        }
    }
}
