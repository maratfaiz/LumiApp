import Foundation

/// F18 — определение кризисных сигналов в том, что пишет пользователь.
///
/// Это **не** ML и не анализ тональности: протокол
/// (`Lumi_Crisis_Protocol.docx` §1) прямо запрещает нейросетевую
/// детекцию — она создаёт ложное ощущение точности. Здесь честное
/// сопоставление с утверждённым списком формулировок, но сделанное
/// аккуратно:
///
/// * текст нормализуется (регистр, `ё`, пунктуация, повторы пробелов);
/// * сравнение идёт по словам, а не по подстроке — иначе «жить» находится
///   внутри «жительница», а «убить» внутри «убитый горем»;
/// * поддерживаются основы со звёздочкой (`умер*` → «умереть», «умерла»);
/// * есть два уровня: `crisis` (немедленный экран помощи) и `concern`
///   (мягкое предложение поддержки, без прерывания занятия);
/// * есть исключения-контексты: пересказ фильма или чужих слов не должен
///   поднимать тревогу.
struct CrisisDetector {
    enum Signal: Equatable {
        /// Ничего не найдено.
        case none
        /// Тяжёлое состояние без прямой угрозы — предлагаем поддержку,
        /// но не прерываем и не отбираем награды.
        case concern
        /// Прямой кризисный сигнал — сразу экран помощи, геймификация
        /// полностью останавливается.
        case crisis
    }

    private let patterns: CrisisPatternSet

    init(patternsProvider: CrisisPatternsProviding = BundledCrisisPatternsProvider()) {
        self.patterns = patternsProvider.loadPatterns()
    }

    /// Совместимость с прежним вызовом: «нужно ли немедленно показать
    /// экран помощи».
    func isCrisisSignal(in text: String) -> Bool {
        evaluate(text) == .crisis
    }

    func evaluate(_ text: String) -> Signal {
        let tokens = Self.tokenize(text)
        guard !tokens.isEmpty else { return .none }

        // Контекст пересказа: «в фильме», «друг сказал» — не сигнал о себе.
        if patterns.exclusions.contains(where: { Self.matches(pattern: $0, in: tokens) }) {
            return .none
        }

        if patterns.crisis.contains(where: { Self.matches(pattern: $0, in: tokens) }) {
            return .crisis
        }
        if patterns.concern.contains(where: { Self.matches(pattern: $0, in: tokens) }) {
            return .concern
        }
        return .none
    }

    // MARK: - Сопоставление

    /// Разбивает текст на слова: нижний регистр, `ё` → `е`, всё, кроме
    /// букв и цифр, считается разделителем.
    static func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    /// Фраза найдена, если её слова идут подряд. Слово с `*` на конце
    /// сравнивается как основа.
    static func matches(pattern: String, in tokens: [String]) -> Bool {
        let parts = pattern
            .lowercased()
            .replacingOccurrences(of: "ё", with: "е")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "*" })
            .map(String.init)
        guard !parts.isEmpty, tokens.count >= parts.count else { return false }

        for start in 0...(tokens.count - parts.count) {
            var isMatch = true
            for offset in parts.indices {
                let token = tokens[start + offset]
                let part = parts[offset]
                if part.hasSuffix("*") {
                    let stem = String(part.dropLast())
                    if stem.isEmpty || !token.hasPrefix(stem) { isMatch = false; break }
                } else if token != part {
                    isMatch = false
                    break
                }
            }
            if isMatch { return true }
        }
        return false
    }
}

/// Списки формулировок. Клинически чувствительная часть — держится
/// отдельно от кода детектора, чтобы её можно было заменить утверждённой
/// психологом версией, не трогая логику.
struct CrisisPatternSet {
    var crisis: [String]
    var concern: [String]
    var exclusions: [String]

    static let empty = CrisisPatternSet(crisis: [], concern: [], exclusions: [])
}

protocol CrisisPatternsProviding {
    func loadPatterns() -> CrisisPatternSet
}

/// Загружает список из бандла с приоритетом:
///
/// 1. `CrisisPatterns.json` — утверждённый психологом список. В git не
///    коммитится (см. `Core/Crisis/README.md`), кладётся в
///    `LumiApp/Resources/` при сборке релиза.
/// 2. `CrisisPatterns.default.json` — **черновой** базовый набор, который
///    едет в репозитории, чтобы детекция работала на дев-сборках и в
///    тестах, а не была выключена.
struct BundledCrisisPatternsProvider: CrisisPatternsProviding {
    func loadPatterns() -> CrisisPatternSet {
        if let approved = decode(resource: "CrisisPatterns") {
            return approved
        }
        if let draft = decode(resource: "CrisisPatterns.default") {
            #if DEBUG
            print("ℹ️ Используется ЧЕРНОВОЙ список кризисных формулировок — заменить утверждённым перед релизом.")
            #endif
            return draft
        }
        #if DEBUG
        print("⚠️ Списка кризисных формулировок нет — детекция ВЫКЛЮЧЕНА. См. Core/Crisis/README.md.")
        #endif
        return .empty
    }

    private func decode(resource: String) -> CrisisPatternSet? {
        guard
            let url = Bundle.main.url(forResource: resource, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        // Новый формат — три списка.
        if let set = try? JSONDecoder().decode(StoredPatternSet.self, from: data) {
            return CrisisPatternSet(crisis: set.crisis, concern: set.concern ?? [], exclusions: set.exclusions ?? [])
        }
        // Старый формат — плоский массив: считаем его кризисным списком.
        if let flat = try? JSONDecoder().decode([String].self, from: data) {
            return CrisisPatternSet(crisis: flat, concern: [], exclusions: [])
        }
        return nil
    }

    private struct StoredPatternSet: Decodable {
        let crisis: [String]
        let concern: [String]?
        let exclusions: [String]?
    }
}
