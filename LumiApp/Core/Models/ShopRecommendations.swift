import Foundation

/// Одна рекомендация: что предложить и, главное, почему. Без объяснения
/// «Популярное» — просто витрина наугад, а с ним это ответ на состояние
/// конкретного пользователя.
struct ShopRecommendation: Identifiable {
    let item: ShopItem
    let reason: String

    var id: String { item.id }
}

/// Вкладка «Популярное» раньше показывала по самому дешёвому товару из
/// каждой категории — то есть одно и то же всем и всегда. Теперь она
/// собирается из состояния пользователя: серия, запас заморозок, ответы
/// онбординга, что уже куплено и сколько люменов на руках.
enum ShopRecommendations {

    static func featured(for progress: UserProgress?, limit: Int = 3) -> [ShopRecommendation] {
        guard let progress else {
            return ShopCatalog.featured.map {
                ShopRecommendation(item: $0, reason: "Хорошее начало")
            }
        }

        var result: [ShopRecommendation] = []

        func add(_ item: ShopItem?, _ reason: String) {
            guard let item, result.count < limit else { return }
            guard !result.contains(where: { $0.item.id == item.id }) else { return }
            // Не рекомендуем то, что уже есть или что нельзя купить в принципе.
            if ShopService.isOwned(item, progress: progress) { return }
            if case .lessonsCompleted = item.unlock { return }
            result.append(ShopRecommendation(item: item, reason: reason))
        }

        let affordable = { (item: ShopItem) -> Bool in
            (item.priceInLumens ?? .max) <= progress.lumens
        }

        // 1. Серия под угрозой: есть что терять, а заморозок нет.
        if progress.currentStreakDays >= 3 && progress.streakFreezesAvailable == 0 {
            add(ShopCatalog.item(id: ShopCatalog.streakFreezeID),
                "Серия \(RussianPlural.days(progress.currentStreakDays)) — заморозка прикроет пропуск")
        }

        // 2. Ответ про формат из онбординга — подбираем технику под него.
        if let format = progress.preferredFormat {
            switch format {
            case .reading:
                add(ShopCatalog.item(id: ShopCatalog.emotionDiaryID),
                    "Ты выбрал(а) чтение и письмо — дневник как раз про это")
            case .audio:
                add(ShopCatalog.item(id: ShopCatalog.selfEmbraceID),
                    "Тихая практика без экрана — под твой формат")
            case .interactive:
                add(ShopCatalog.item(id: ShopCatalog.valuesFocusID),
                    "Короткое задание на день — под твой формат")
            }
        }

        // 3. Цель из онбординга.
        if let goal = progress.goal {
            switch goal {
            case .lessCritical:
                add(ShopCatalog.item(id: ShopCatalog.selfEmbraceID),
                    "Помогает, когда внутренний критик громкий")
            case .anxietyEase:
                add(ShopCatalog.item(id: ShopCatalog.emotionDiaryID),
                    "Назвать тревогу — первый шаг к тому, чтобы её отпустило")
            case .selfWorth, .confidence:
                add(ShopCatalog.item(id: ShopCatalog.valuesFocusID),
                    "Опора на ценности, а не на оценку себя")
            case .other:
                break
            }
        }

        // 4. Первый образ — если люменов уже хватает, а гардероб пуст.
        let ownedSkins = ShopCatalog.accessories.filter { ShopService.isOwned($0, progress: progress) }
        if ownedSkins.isEmpty {
            add(ShopCatalog.accessories.filter(affordable).min { ($0.priceInLumens ?? 0) < ($1.priceInLumens ?? 0) },
                "Первый образ для Луми — уже по карману")
        }

        // 5. Застрял на уроке и нет подсказок.
        if progress.completedLessonIDs.count >= 2 && progress.lessonHintTokens == 0 {
            add(ShopCatalog.item(id: ShopCatalog.lessonHintID),
                "Подскажет пример ответа, если упражнение застопорилось")
        }

        // 6. Копятся люмены — предложить следующий по цене образ.
        if progress.lumens >= 150 {
            add(ShopCatalog.accessories
                .filter { affordable($0) && !ShopService.isOwned($0, progress: progress) }
                .max { ($0.priceInLumens ?? 0) < ($1.priceInLumens ?? 0) },
                "Хватает на редкий образ — потрать на что-то приятное")
        }

        // 7. Практикует много — доп. задание окупится.
        if progress.practiceSessionCount >= 5 && progress.extraDailyTaskTokens == 0 {
            add(ShopCatalog.item(id: ShopCatalog.extraTaskID),
                "Ты часто занимаешься — это снимет дневной лимит на награду")
        }

        // Добор до лимита: самое дешёвое из доступного.
        if result.count < limit {
            for item in ShopCatalog.all.sorted(by: { ($0.priceInLumens ?? 0) < ($1.priceInLumens ?? 0) }) {
                add(item, affordable(item) ? "По карману прямо сейчас" : "Ближайшая цель")
            }
        }

        return result
    }
}
