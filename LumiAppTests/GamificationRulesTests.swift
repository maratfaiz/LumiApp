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
        var crisis: [String] = []
        var concern: [String] = []
        var exclusions: [String] = []
        func loadPatterns() -> CrisisPatternSet {
            CrisisPatternSet(crisis: crisis, concern: concern, exclusions: exclusions)
        }
    }

    @Test func detectsPhraseRegardlessOfCaseAndPunctuation() {
        let detector = CrisisDetector(patternsProvider: FakeProvider(crisis: ["не хочу жить"]))
        #expect(detector.evaluate("Честно — Не Хочу Жить, всё надоело") == .crisis)
        #expect(detector.isCrisisSignal(in: "не хочу жить"))
    }

    @Test func matchesWholeWordsNotSubstrings() {
        // «жить» внутри «жительница» не должно поднимать тревогу — ровно та
        // ошибка, которую давало сравнение подстрокой.
        let detector = CrisisDetector(patternsProvider: FakeProvider(crisis: ["жить"]))
        #expect(detector.evaluate("я жительница маленького города") == .none)
        #expect(detector.evaluate("тяжело жить") == .crisis)
    }

    @Test func stemPatternsMatchWordForms() {
        let detector = CrisisDetector(patternsProvider: FakeProvider(crisis: ["хочу умер*"]))
        #expect(detector.evaluate("иногда хочу умереть") == .crisis)
        #expect(detector.evaluate("хочу умерла бы") == .crisis)
        #expect(detector.evaluate("хочу умный ответ") == .none)
    }

    @Test func yoIsNormalized() {
        let detector = CrisisDetector(patternsProvider: FakeProvider(crisis: ["всё бессмысленно"]))
        #expect(detector.evaluate("все бессмысленно") == .crisis)
    }

    @Test func concernIsSeparateFromCrisis() {
        let detector = CrisisDetector(
            patternsProvider: FakeProvider(crisis: ["не хочу жить"], concern: ["мне очень плохо"])
        )
        #expect(detector.evaluate("мне очень плохо сегодня") == .concern)
        #expect(detector.isCrisisSignal(in: "мне очень плохо сегодня") == false)
    }

    @Test func retellingIsExcluded() {
        let detector = CrisisDetector(
            patternsProvider: FakeProvider(crisis: ["не хочу жить"], exclusions: ["в фильм*"])
        )
        #expect(detector.evaluate("в фильме герой говорил «не хочу жить»") == .none)
    }

    @Test func emptyPatternListNeverMatches() {
        let detector = CrisisDetector(patternsProvider: FakeProvider())
        #expect(detector.evaluate("что угодно") == .none)
    }

    /// Защита от регресса: прошлые суицидальные мысли — сильнейший предиктор
    /// будущих, поэтому формулировки о собственном прошлом состоянии нельзя
    /// добавлять в исключения.
    @Test func pastIdeationIsNotExcluded() {
        let detector = CrisisDetector(
            patternsProvider: FakeProvider(crisis: ["не хочу жить"], exclusions: ["в фильм*"])
        )
        #expect(detector.evaluate("раньше думал что не хочу жить, и сейчас опять") == .crisis)
    }
}
