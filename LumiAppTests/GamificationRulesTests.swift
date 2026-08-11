import Testing
@testable import LumiApp

struct GamificationRulesTests {
    @Test func level1AtZeroXP() {
        #expect(GamificationRules.level(forXP: 0) == 1)
    }

    @Test func level2At30XP() {
        #expect(GamificationRules.level(forXP: 30) == 2)
    }

    @Test func level5At180XP() {
        #expect(GamificationRules.level(forXP: 180) == 5)
        #expect(GamificationRules.level(forXP: 999) == 5)
    }

    @Test func xpToNextLevel() {
        #expect(GamificationRules.xpToNextLevel(currentXP: 20) == 10)
        #expect(GamificationRules.xpToNextLevel(currentXP: 180) == nil)
    }
}

struct CrisisDetectorTests {
    private struct FakeProvider: CrisisPatternsProviding {
        let patterns: [String]
        func loadPatterns() -> [String] { patterns }
    }

    @Test func detectsCaseInsensitiveSubstring() {
        let detector = CrisisDetector(patternsProvider: FakeProvider(patterns: ["test trigger"]))
        #expect(detector.isCrisisSignal(in: "this is a Test Trigger in a sentence"))
    }

    @Test func noFalsePositiveWithoutMatch() {
        let detector = CrisisDetector(patternsProvider: FakeProvider(patterns: ["test trigger"]))
        #expect(!detector.isCrisisSignal(in: "an ordinary lesson answer"))
    }

    @Test func emptyPatternListNeverMatches() {
        let detector = CrisisDetector(patternsProvider: FakeProvider(patterns: []))
        #expect(!detector.isCrisisSignal(in: "anything at all"))
    }
}
