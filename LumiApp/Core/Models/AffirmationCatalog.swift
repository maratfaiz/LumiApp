import Foundation

struct Affirmation: Identifiable, Hashable {
    let id: String
    let text: String
}

/// F27 placeholder card copy — UNREVIEWED, pending psychologist/copywriter
/// approval (same caveat as QuoteOfTheDay). Structure (10+ short,
/// self-compassion-oriented statements) matches the prototype's card deck.
enum AffirmationCatalog {
    static let all: [Affirmation] = [
        Affirmation(id: "aff-1", text: "Я имею право на ошибки — это часть роста."),
        Affirmation(id: "aff-2", text: "Я делаю всё, что могу, с теми ресурсами, что у меня есть сейчас."),
        Affirmation(id: "aff-3", text: "Моя ценность не зависит от того, насколько я продуктивен(на) сегодня."),
        Affirmation(id: "aff-4", text: "Я могу быть добрым(ой) к себе, даже когда всё идёт не по плану."),
        Affirmation(id: "aff-5", text: "Я учусь, а не проваливаюсь."),
        Affirmation(id: "aff-6", text: "Мои чувства имеют значение, даже если другие их не понимают."),
        Affirmation(id: "aff-7", text: "Я не обязан(а) быть идеальным(ой), чтобы заслуживать заботу."),
        Affirmation(id: "aff-8", text: "Я разрешаю себе двигаться в своём темпе."),
        Affirmation(id: "aff-9", text: "Сравнение с другими не определяет мой путь."),
        Affirmation(id: "aff-10", text: "Я горжусь тем, что продолжаю пробовать."),
        Affirmation(id: "aff-11", text: "Моё мнение о себе может быть добрее, чем внутренний критик."),
        Affirmation(id: "aff-12", text: "Отдых — это тоже часть заботы о себе."),
    ]
}
