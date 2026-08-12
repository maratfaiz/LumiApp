import Foundation

/// Что даёт уровень. Раньше уровень был просто числом на экране профиля:
/// XP росли, полоска двигалась, и на этом всё — повышение ничего не меняло.
/// Теперь у каждого уровня есть звание и разовая награда.
struct LevelReward: Equatable {
    let level: Int
    /// Звание — это и есть «статусная» часть уровня.
    let title: String
    let lumens: Int
    let freezes: Int
    let hintTokens: Int
    let extraTaskTokens: Int
    /// Образ, который выдаётся в подарок (id из ShopCatalog.accessories).
    let skinID: String?

    init(
        level: Int,
        title: String,
        lumens: Int = 0,
        freezes: Int = 0,
        hintTokens: Int = 0,
        extraTaskTokens: Int = 0,
        skinID: String? = nil
    ) {
        self.level = level
        self.title = title
        self.lumens = lumens
        self.freezes = freezes
        self.hintTokens = hintTokens
        self.extraTaskTokens = extraTaskTokens
        self.skinID = skinID
    }

    /// Человекочитаемый список наград — для экрана «новый уровень».
    var rewardLines: [String] {
        var lines: [String] = []
        if lumens > 0 { lines.append("+\(lumens) люменов") }
        if freezes > 0 { lines.append("+\(RussianPlural.freezes(freezes)) серии") }
        if hintTokens > 0 { lines.append("+\(hintTokens) подсказка в уроке") }
        if extraTaskTokens > 0 { lines.append("+\(extraTaskTokens) доп. задание дня") }
        if let skinID, let item = ShopCatalog.item(id: skinID) {
            lines.append("Образ «\(item.title)» — в подарок")
        }
        return lines
    }
}

enum LevelSystem {
    /// Звания намеренно про наблюдение и практику, а не про «крутость»:
    /// уровень не должен читаться как оценка человека.
    static let rewards: [LevelReward] = [
        LevelReward(level: 2, title: "Первые шаги", lumens: 25),
        LevelReward(level: 3, title: "Наблюдатель", lumens: 25, freezes: 1),
        LevelReward(level: 4, title: "Замечающий", lumens: 30, hintTokens: 1),
        LevelReward(level: 5, title: "Практик", lumens: 40, skinID: "skin-classic"),
        LevelReward(level: 6, title: "Внимательный к себе", lumens: 40, extraTaskTokens: 1),
        LevelReward(level: 7, title: "Устойчивый", lumens: 50, freezes: 1),
        LevelReward(level: 8, title: "Опора себе", lumens: 50, hintTokens: 1),
        LevelReward(level: 9, title: "Спокойная сила", lumens: 60, extraTaskTokens: 1),
        LevelReward(level: 10, title: "Свой человек себе", lumens: 80, skinID: "skin-night"),
    ]

    static func reward(for level: Int) -> LevelReward? {
        rewards.first { $0.level == level }
    }

    static func title(for level: Int) -> String {
        reward(for: level)?.title ?? "Начало пути"
    }

    /// Выдаёт награды за все уровни, которых пользователь достиг, но ещё не
    /// получил. Идемпотентно: повторный вызов ничего не начислит.
    /// Возвращает выданные награды, чтобы экран мог их показать.
    @discardableResult
    static func claimPendingRewards(for progress: UserProgress) -> [LevelReward] {
        let currentLevel = progress.level
        let pending = rewards
            .filter { $0.level <= currentLevel && !progress.claimedLevelRewards.contains($0.level) }
            .sorted { $0.level < $1.level }

        for reward in pending {
            progress.claimedLevelRewards.append(reward.level)
            progress.lumens += reward.lumens
            if reward.freezes > 0 {
                progress.streakFreezesAvailable = min(
                    progress.streakFreezesAvailable + reward.freezes,
                    GamificationRules.maxStoredStreakFreezes
                )
            }
            progress.hintTokens(add: reward.hintTokens)
            progress.extraTasks(add: reward.extraTaskTokens)
            if let skinID = reward.skinID, !progress.unlockedMascotSkinIDs.contains(skinID) {
                progress.unlockedMascotSkinIDs.append(skinID)
            }
        }

        return pending
    }
}

extension UserProgress {
    var levelTitle: String { LevelSystem.title(for: level) }

    func hintTokens(add count: Int) {
        guard count > 0 else { return }
        lessonHintTokens += count
    }

    func extraTasks(add count: Int) {
        guard count > 0 else { return }
        extraDailyTaskTokens += count
    }
}
