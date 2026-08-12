import SwiftData
import SwiftUI

/// F10 — greeting, streak/lumens/freezes chips, mascot (tappable →
/// wardrobe), current-lesson card, F26/F27/F29 mode tiles ("Сегодня для
/// тебя"), wardrobe promo, "Мысль дня". Ported from the design's `is.home`
/// screen.
struct HomeView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var currentCourse: Course? {
        CourseCatalog.courses.first { $0.id == progress?.currentCourseID }
    }

    private var nextLesson: Lesson? {
        guard let currentCourse else { return nil }
        let completed = Set(progress?.completedLessonIDs ?? [])
        return currentCourse.lessons.first { !completed.contains($0.id) } ?? currentCourse.lessons.last
    }

    private var completedLessonsInCurrentCourse: Int {
        guard let currentCourse else { return 0 }
        let completed = Set(progress?.completedLessonIDs ?? [])
        return currentCourse.lessons.filter { completed.contains($0.id) }.count
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 14) {
                header

                NavigationLink(destination: WardrobeView()) {
                    EquippedMascotView(size: 150)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                freezeNotice

                currentLessonCard

                SectionLabel(text: "Сегодня для тебя")
                modeTiles

                unlockedTechniques

                if !(progress?.favoriteAffirmationIDs.isEmpty ?? true) {
                    favoritesCard
                }

                wardrobePromo
                quoteOfTheDayCard
            }
        }
        // The design's root screens carry their own heading in content —
        // no system navigation bar.
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 6) {
            Text(greeting)
                .font(.lumi(18, weight: .black))
                .foregroundStyle(Color.white)
                .lineLimit(1)
            Spacer(minLength: 6)
            if let progress {
                StatChip(
                    icon: "icon-streak",
                    text: "\(progress.currentStreakDays)",
                    color: LumiColor.orange1,
                    fallbackSystemImage: "flame.fill"
                )
                NavigationLink(destination: ShopView()) {
                    StatChip(
                        icon: "icon-lumen",
                        text: "\(progress.lumens)",
                        color: LumiColor.yellow,
                        fallbackSystemImage: "star.fill"
                    )
                }
                .buttonStyle(.plain)
                StatChip(
                    icon: "icon-freeze",
                    text: "\(progress.streakFreezesAvailable)/\(GamificationRules.maxStoredStreakFreezes)",
                    color: LumiColor.blueChip,
                    fallbackSystemImage: "snowflake"
                )
            }
        }
    }

    private var greeting: String {
        if let name = progress?.userDisplayName, !name.isEmpty {
            return "Привет, \(name)!"
        }
        return "Привет!"
    }

    // MARK: Current lesson

    @ViewBuilder private var currentLessonCard: some View {
        if let currentCourse, let nextLesson {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Текущий урок")
                Text("Курс \(currentCourse.number). \(currentCourse.title)")
                    .font(.lumi(14, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Урок \(nextLesson.indexInCourse). \(nextLesson.title) · \(completedLessonsInCurrentCourse)/\(currentCourse.lessons.count)")
                    .font(.lumi(12, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink(destination: LessonPlayerView(course: currentCourse, lesson: nextLesson)) {
                    Text("Продолжить урок →")
                        .font(.lumi(15, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.plain)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LumiGradient.primary))
                .shadow(color: LumiColor.purple2.opacity(0.45), radius: 14, y: 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lumiCard()
        }
    }

    // MARK: Mode tiles

    /// Порядок практик — это и есть работа 3-го вопроса онбординга:
    /// выбранный формат ставит подходящую практику первой и помечает её.
    private var orderedPractices: [Practice] {
        switch progress?.preferredFormat {
        case .audio: return [.meditation, .affirmations, .breathing]
        case .reading: return [.affirmations, .breathing, .meditation]
        case .interactive, nil: return [.breathing, .affirmations, .meditation]
        }
    }

    private var modeTiles: some View {
        HStack(spacing: 8) {
            ForEach(Array(orderedPractices.enumerated()), id: \.element) { index, practice in
                modeTile(practice: practice, isSuggested: index == 0 && progress?.preferredFormat != nil)
            }
        }
    }

    @ViewBuilder
    private func modeTile(practice: Practice, isSuggested: Bool) -> some View {
        switch practice {
        case .breathing:
            modeTile(icon: "moon", title: practice.title, isSuggested: isSuggested, destination: BreathingView())
        case .affirmations:
            modeTile(icon: "icon-heart-fill", title: practice.title, isSuggested: isSuggested, destination: AffirmationsView())
        case .meditation:
            modeTile(icon: "sun.max", title: practice.title, isSuggested: isSuggested, destination: MeditationView())
        }
    }

    private func modeTile(icon: String, title: String, isSuggested: Bool, destination: some View) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                LumiGlyph(name: icon, size: 17)
                    .foregroundStyle(isSuggested ? Color.white : LumiColor.purpleLight)
                Text(title)
                    .font(.lumi(10, weight: .bold))
                    .foregroundStyle(isSuggested ? Color.white : LumiColor.textBody)
                if isSuggested {
                    Text("твой формат")
                        .font(.lumi(8.5, weight: .bold))
                        .foregroundStyle(LumiColor.purpleLight)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSuggested ? LumiColor.purple1.opacity(0.18) : LumiColor.cardFillLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSuggested ? LumiColor.purple1.opacity(0.5) : LumiColor.cardBorder, lineWidth: 1)
        )
    }

    // MARK: Techniques bought in the shop

    private var ownedTechniques: [ShopItem] {
        ShopCatalog.secretTechniques.filter { ShopService.isOwned($0, progress: progress) }
    }

    @ViewBuilder private var unlockedTechniques: some View {
        if !ownedTechniques.isEmpty {
            SectionLabel(text: "Твои техники")
            HStack(spacing: 8) {
                ForEach(ownedTechniques) { item in
                    NavigationLink(destination: TechniqueScreen(item: item)) {
                        VStack(spacing: 6) {
                            ShopItemArtwork(item: item, size: 28)
                            Text(item.title)
                                .font(.lumi(10, weight: .bold))
                                .foregroundStyle(LumiColor.textBody)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LumiColor.cardFillLight))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LumiColor.cardBorder, lineWidth: 1))
                }
            }
        }
    }

    /// Избранные аффирмации теперь возвращаются к пользователю сами —
    /// одна из отмеченных фраз показывается на главной.
    @ViewBuilder private var favoritesCard: some View {
        if let affirmation = favoriteOfTheDay {
            NavigationLink(destination: FavoriteAffirmationsView()) {
                HStack(alignment: .top, spacing: 11) {
                    LumiIcon(name: "icon-quote", size: 16, fallbackSystemImage: "quote.opening")
                        .foregroundStyle(LumiColor.purple1.opacity(0.7))
                    VStack(alignment: .leading, spacing: 3) {
                        SectionLabel(text: "Твои слова", color: LumiColor.purpleLight, size: 10)
                        Text(affirmation.text)
                            .font(.lumi(12.5, weight: .semibold))
                            .foregroundStyle(LumiColor.textBright)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .lumiCard(fill: LumiColor.cardFillLight, radius: 14)
        }
    }

    /// Детерминированный выбор по дню — фраза не прыгает при каждом
    /// обновлении экрана.
    private var favoriteOfTheDay: Affirmation? {
        guard let progress else { return nil }
        let favorites = AffirmationCatalog.fullDeck(custom: progress.customAffirmations)
            .filter { progress.favoriteAffirmationIDs.contains($0.id) }
        guard !favorites.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return favorites[dayOfYear % favorites.count]
    }

    // MARK: Freeze notice

    /// Заморозка срабатывает сама (StreakEngine) — без этой карточки
    /// пользователь бы просто не заметил, что покупка сработала.
    @ViewBuilder private var freezeNotice: some View {
        if let usedAt = recentFreezeDate {
            HStack(spacing: 11) {
                ZStack {
                    Circle().fill(LumiColor.blueChip.opacity(0.18)).frame(width: 34, height: 34)
                    LumiIcon(name: "icon-freeze", size: 16, fallbackSystemImage: "snowflake")
                        .foregroundStyle(LumiColor.blueChip)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Заморозка сохранила серию")
                        .font(.lumi(12.5, weight: .heavy))
                        .foregroundStyle(Color.white)
                    Text(usedAt, format: .dateTime.day().month())
                        .font(.lumi(10.5, weight: .semibold))
                        .foregroundStyle(LumiColor.blueChip)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lumiAccentCard(LumiColor.blueChip, radius: 14)
        }
    }

    private var recentFreezeDate: Date? {
        guard let progress else { return nil }
        let calendar = Calendar.current
        guard let threshold = calendar.date(byAdding: .day, value: -3, to: .now) else { return nil }
        return progress.freezeUsedDates.filter { $0 >= threshold }.max()
    }

    // MARK: Wardrobe promo

    private var wardrobePromo: some View {
        NavigationLink(destination: WardrobeView()) {
            HStack(spacing: 12) {
                LumiMascot(assetName: "mascot-home-wardrobe", size: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Создай стиль для Луми и подними ему настроение")
                        .font(.lumi(12, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Гардероб →")
                        .font(.lumi(11, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LumiColor.cardFillLight))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundStyle(Color.white.opacity(0.15))
        )
    }

    // MARK: Quote of the day

    private var quoteOfTheDayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Мысль дня", color: LumiColor.purpleLight, size: 10)
            Text(QuoteOfTheDay.current(goal: progress?.goal))
                .font(.lumi(13, weight: .medium))
                .foregroundStyle(Color(hex: 0xF0ECFF))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LumiColor.purple1.opacity(0.16), LumiColor.purple2.opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LumiColor.purple1.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack { HomeView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
