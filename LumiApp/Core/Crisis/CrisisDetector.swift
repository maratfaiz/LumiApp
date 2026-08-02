import Foundation

/// Simple keyword/pattern matching — NOT AI sentiment analysis. The protocol
/// doc explicitly rules out ML-based detection here: it would create false
/// confidence in accuracy that a plain pattern match doesn't pretend to have
/// (Lumi_Crisis_Protocol.docx §1).
///
/// The actual trigger phrase list is clinically sensitive and, per the same
/// document, must not be published in open product docs — so it is NOT
/// hardcoded in this file. See Core/Crisis/README.md for how to supply it.
struct CrisisDetector {
    private let patterns: [String]

    init(patternsProvider: CrisisPatternsProviding = BundledCrisisPatternsProvider()) {
        self.patterns = patternsProvider.loadPatterns()
    }

    func isCrisisSignal(in text: String) -> Bool {
        guard !patterns.isEmpty else { return false }
        let normalized = text.lowercased()
        return patterns.contains { normalized.contains($0.lowercased()) }
    }
}

protocol CrisisPatternsProviding {
    func loadPatterns() -> [String]
}

/// Loads `CrisisPatterns.json` (a flat `[String]`) from the app bundle if a
/// developer has placed one there. Absent that file, returns an empty list —
/// detection is a no-op rather than crashing, but this is a silent safety
/// gap, so it logs loudly in debug builds.
struct BundledCrisisPatternsProvider: CrisisPatternsProviding {
    func loadPatterns() -> [String] {
        guard
            let url = Bundle.main.url(forResource: "CrisisPatterns", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let patterns = try? JSONDecoder().decode([String].self, from: data)
        else {
            #if DEBUG
            print("⚠️ CrisisPatterns.json not found — crisis detection is DISABLED. See Core/Crisis/README.md.")
            #endif
            return []
        }
        return patterns
    }
}
