import Foundation
import SwiftData

/// Запись «Дневника эмоций» — техники, которая открывается покупкой в
/// магазине (F13/F30). Хранится в том же контейнере, что и прогресс.
@Model
final class JournalEntry {
    var createdAt: Date
    /// Эмоция из `JournalEmotion.rawValue` (строкой — чтобы список эмоций
    /// можно было расширять без миграции схемы).
    var emotionRawValue: String
    /// 1...5 — насколько сильно.
    var intensity: Int
    /// Что случилось / из-за чего. Может быть пустым.
    var note: String

    init(createdAt: Date = .now, emotionRawValue: String, intensity: Int, note: String) {
        self.createdAt = createdAt
        self.emotionRawValue = emotionRawValue
        self.intensity = intensity
        self.note = note
    }

    var emotion: JournalEmotion? { JournalEmotion(rawValue: emotionRawValue) }
}

/// Базовый набор эмоций. Формулировки нейтральные, без оценок «хорошая» /
/// «плохая» — называние чувства само по себе и есть упражнение.
enum JournalEmotion: String, CaseIterable, Identifiable {
    case joy = "Радость"
    case calm = "Спокойствие"
    case sadness = "Грусть"
    case anxiety = "Тревога"
    case anger = "Злость"
    case shame = "Стыд"
    case tiredness = "Усталость"
    case gratitude = "Благодарность"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .joy: return "icon-smile"
        case .calm: return "icon-ambience-ocean"
        case .sadness: return "icon-heart-outline"
        case .anxiety: return "icon-anxiety"
        case .anger: return "icon-bolt"
        case .shame: return "icon-critic-voice"
        case .tiredness: return "icon-clock"
        case .gratitude: return "icon-heart-fill"
        }
    }
}
