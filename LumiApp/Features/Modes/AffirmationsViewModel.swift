import AVFoundation
import Observation

/// F27 — swipeable affirmation deck with optional read-aloud via
/// AVSpeechSynthesizer (no licensed audio needed — unlike F29's ambients).
@Observable
final class AffirmationsViewModel: NSObject {
    private(set) var currentIndex = 0
    private(set) var isSpeaking = false
    private(set) var viewedIndices: Set<Int> = [0]
    private(set) var rewardGranted = false
    var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate

    private let synthesizer = AVSpeechSynthesizer()
    private var cards: [Affirmation]

    init(cards: [Affirmation] = AffirmationCatalog.all) {
        self.cards = cards
        super.init()
        synthesizer.delegate = self
    }

    var current: Affirmation { cards[min(currentIndex, max(cards.count - 1, 0))] }

    /// Меняет колоду на лету — например, при переключении «только
    /// избранные». Пустую колоду не принимаем, иначе экран остался бы без
    /// карточек.
    func replaceDeck(_ newCards: [Affirmation]) {
        guard !newCards.isEmpty, newCards.map(\.id) != cards.map(\.id) else { return }
        stopSpeaking()
        cards = newCards
        currentIndex = 0
        viewedIndices = [0]
        rewardGranted = false
    }
    var cardCount: Int { cards.count }
    var isSessionComplete: Bool { viewedIndices.count >= cards.count }

    func isFavorite(_ id: String, in favoriteIDs: [String]) -> Bool {
        favoriteIDs.contains(id)
    }

    func next() {
        stopSpeaking()
        currentIndex = (currentIndex + 1) % cards.count
        viewedIndices.insert(currentIndex)
    }

    func previous() {
        stopSpeaking()
        currentIndex = (currentIndex - 1 + cards.count) % cards.count
        viewedIndices.insert(currentIndex)
    }

    func speakCurrent() {
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: current.text)
        utterance.rate = speechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "ru-RU")
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    func markRewardGranted() {
        rewardGranted = true
    }
}

extension AffirmationsViewModel: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
