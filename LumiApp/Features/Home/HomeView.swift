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

                currentLessonCard

                SectionLabel(text: "Сегодня для тебя")
                modeTiles

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

    private var modeTiles: some View {
        HStack(spacing: 8) {
            modeTile(icon: "moon", title: "Дыхание", destination: BreathingView())
            modeTile(icon: "icon-heart-fill", title: "Аффирмации", destination: AffirmationsView())
            modeTile(icon: "sun.max", title: "Медитация", destination: MeditationView())
        }
    }

    private func modeTile(icon: String, title: String, destination: some View) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                LumiGlyph(name: icon, size: 17)
                    .foregroundStyle(LumiColor.purpleLight)
                Text(title)
                    .font(.lumi(10, weight: .bold))
                    .foregroundStyle(LumiColor.textBody)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(RoundedRectangle(cornerRadius: 12).fill(LumiColor.cardFillLight))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LumiColor.cardBorder, lineWidth: 1))
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
            Text(QuoteOfTheDay.current())
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
