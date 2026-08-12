import Foundation

/// Russian noun agreement for the counts the UI shows ("1 урок", "2 урока",
/// "5 уроков"). The design's mock-ups are all written in correct Russian, so
/// the ported screens need the same instead of "урок(ов)".
enum RussianPlural {
    /// - Parameters:
    ///   - one: form for 1, 21, 31… ("урок")
    ///   - few: form for 2–4, 22–24… ("урока")
    ///   - many: form for 0, 5–20, 25–30… ("уроков")
    static func form(_ count: Int, one: String, few: String, many: String) -> String {
        let absolute = abs(count)
        let lastTwo = absolute % 100
        if (11...14).contains(lastTwo) { return many }
        switch absolute % 10 {
        case 1: return one
        case 2, 3, 4: return few
        default: return many
        }
    }

    static func lessons(_ count: Int) -> String {
        "\(count) " + form(count, one: "урок", few: "урока", many: "уроков")
    }

    static func days(_ count: Int) -> String {
        "\(count) " + form(count, one: "день", few: "дня", many: "дней")
    }

    static func daysInARow(_ count: Int) -> String {
        form(count, one: "день подряд", few: "дня подряд", many: "дней подряд")
    }

    static func freezes(_ count: Int) -> String {
        "\(count) " + form(count, one: "заморозка", few: "заморозки", many: "заморозок")
    }
}
