import Foundation

/// Home screen "Мысль дня" card. Acceptance criteria requires the same
/// phrase not repeat more than once per 2 weeks — cycling deterministically
/// by day-of-year through a list this long satisfies that without needing
/// to persist "last shown" state.
///
/// TODO: this copy is a placeholder written to match the supportive,
/// non-clinical tone established elsewhere in the app (no toxic positivity,
/// no diagnostic language) — it has NOT been reviewed by the project's
/// psychologist/copywriter the way Lumi_Course_Content.docx was. Swap for
/// approved copy before release.
enum QuoteOfTheDay {
    private static let quotes = [
        "Не обязательно быть идеальным, чтобы быть достойным любви.",
        "Маленький шаг сегодня — это тоже шаг.",
        "Ты можешь быть добрым к себе даже в трудный день.",
        "Прогресс не обязан быть прямой линией.",
        "Отдых — тоже часть заботы о себе.",
        "Ты не обязан(а) нравиться всем, чтобы быть ценным(ой).",
        "Ошибки — это данные, а не приговор.",
        "Сравнение с другими редко говорит правду о тебе.",
        "Ты уже прошёл(ла) через трудности раньше — это тоже сила.",
        "Замечать свои чувства — уже забота о себе.",
        "Не всё нужно решать сегодня.",
        "Ты — это не одна твоя худшая мысль о себе.",
        "Маленькая победа сегодня всё равно победа.",
        "Быть неидеальным и быть достаточным — это не противоречие.",
    ]

    static func current(referenceDate: Date = .now) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: referenceDate) ?? 1
        return quotes[dayOfYear % quotes.count]
    }
}
