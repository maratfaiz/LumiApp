import SwiftData
import SwiftUI

/// F10 — greeting, streak/lumens/freezes badges, mascot (tappable →
/// wardrobe), current-lesson card, F26/F27/F29 mode tiles ("Сегодня для
/// тебя"), wardrobe promo, "Мысль дня". Matches docs/design/prototype's
/// is.home screen.
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    NavigationLink(destination: WardrobeView()) {
                        MascotView(state: .neutral)
                            .frame(width: 150, height: 150)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)

                    currentLessonCard

                    Text("Сегодня для тебя")
                        .font(.lumiCaption.bold())
                        .foregroundStyle(.secondary)
                    modeTiles

                    wardrobePromo
                    quoteOfTheDayCard
                }
                .padding()
            }
            .navigationTitle("Луми")
        }
    }

    private var header: some View {
        HStack {
            if let name = progress?.userDisplayName, !name.isEmpty {
                Text("Привет, \(name)!").font(.lumiHeadline)
            } else {
                Text("Привет!").font(.lumiHeadline)
            }
            Spacer()
            if let progress {
                Label("\(progress.currentStreakDays)", systemImage: "flame.fill")
                    .foregroundStyle(.orange)
                NavigationLink(destination: ShopView()) {
                    Label("\(progress.lumens)", systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                }
                Label("\(progress.streakFreezesAvailable)/\(GamificationRules.maxStoredStreakFreezes)", systemImage: "snowflake")
                    .foregroundStyle(.blue)
            }
        }
        .font(.lumiCaption.bold())
    }

    @ViewBuilder private var currentLessonCard: some View {
        if let currentCourse, let nextLesson {
            VStack(alignment: .leading, spacing: 8) {
                Text("ТЕКУЩИЙ УРОК").font(.lumiCaption.bold()).foregroundStyle(.secondary)
                Text("Курс \(currentCourse.number). \(currentCourse.title)").font(.lumiBody.bold())
                Text("Урок \(nextLesson.indexInCourse). \(nextLesson.title) · \(completedLessonsInCurrentCourse)/\(currentCourse.lessons.count)")
                    .font(.lumiCaption)
                    .foregroundStyle(.secondary)
                NavigationLink(destination: LessonPlayerView(course: currentCourse, lesson: nextLesson)) {
                    Text("Продолжить урок →")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
            }
            .padding()
            .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var modeTiles: some View {
        HStack(spacing: 8) {
            modeTile(title: "Дыхание", systemImage: "wind", destination: BreathingView())
            modeTile(title: "Аффирмации", systemImage: "heart.fill", destination: AffirmationsView())
            modeTile(title: "Медитация", systemImage: "moon.stars.fill", destination: MeditationView())
        }
    }

    private func modeTile(title: String, systemImage: String, destination: some View) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title).font(.lumiCaption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var wardrobePromo: some View {
        NavigationLink(destination: WardrobeView()) {
            HStack(spacing: 12) {
                MascotView(state: .neutral).frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text("Создай стиль для Луми и подними ему настроение").font(.lumiCaption.bold())
                    Text("Гардероб →").font(.lumiCaption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4])))
        }
        .buttonStyle(.plain)
    }

    private var quoteOfTheDayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("МЫСЛЬ ДНЯ").font(.lumiCaption.bold()).foregroundStyle(LumiColor.accent)
            Text(QuoteOfTheDay.current()).font(.lumiBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
