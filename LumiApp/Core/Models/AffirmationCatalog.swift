import Foundation

struct Affirmation: Identifiable, Hashable {
    let id: String
    let text: String
    /// Написана пользователем, а не взята из каталога.
    var isCustom: Bool = false
}

/// F27. Колода аффирмаций: каталожные + свои.
///
/// Избранное теперь не просто сердечко «в никуда»: отмеченные карточки
/// собираются в отдельный список, из них можно составить колоду «только
/// избранные», и они подставляются в карточку «Мысль дня» на главной.
///
/// TODO: копирайт написан в согласованном тоне, но психологом/копирайтером
/// не утверждён (в отличие от `CourseCatalog`) — заменить перед релизом.
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

    static let customIDPrefix = "aff-custom-"

    static func customID(for text: String) -> String {
        customIDPrefix + String(text.hashValue.magnitude)
    }

    /// Свои аффирмации как карточки колоды.
    static func customCards(from texts: [String]) -> [Affirmation] {
        texts.map { Affirmation(id: customID(for: $0), text: $0, isCustom: true) }
    }

    /// Полная колода: каталог + свои.
    static func fullDeck(custom: [String]) -> [Affirmation] {
        all + customCards(from: custom)
    }

    /// Колода «только избранные». Если избранного нет — возвращает полную,
    /// чтобы экран практики никогда не оказался пустым.
    static func favoritesDeck(favoriteIDs: [String], custom: [String]) -> [Affirmation] {
        let favorites = fullDeck(custom: custom).filter { favoriteIDs.contains($0.id) || $0.isCustom }
        return favorites.isEmpty ? fullDeck(custom: custom) : favorites
    }

    static func affirmation(id: String, custom: [String]) -> Affirmation? {
        fullDeck(custom: custom).first { $0.id == id }
    }
}
