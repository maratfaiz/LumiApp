import SwiftData
import SwiftUI

/// F8 — explanation → exercise → example. On submit, user text is checked
/// against the crisis detector *before* anything else happens — a crisis
/// match must short-circuit straight to CrisisSupportView with zero rewards
/// granted (Lumi_Crisis_Protocol.docx §2).
///
/// Layout ported from the design's lesson + exercise screens: lesson
/// progress bar, per-mechanic mascot pose, explanation card, exercise, and
/// the always-available "мне сейчас тяжело" escape hatch above the CTA.
struct LessonPlayerView: View {
    let course: Course
    let lesson: Lesson

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    @State private var answerText = ""
    @State private var showCompletion = false
    @State private var showCrisisSupport = false

    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0

    private let crisisDetector = CrisisDetector()

    /// Reuses the design's own per-mechanic mascot pose (mascot-ex1…ex10),
    /// so each exercise type visually matches how it looked in the
    /// prototype, instead of one static image.
    private var mascotAssetName: String {
        switch lesson.exerciseKind {
        case .freeText: return "mascot-lesson"
        case .choiceOrCustom: return "mascot-ex1"
        case .factOrJudgment: return "mascot-ex3"
        case .rewriteAsFact: return "mascot-ex4"
        case .defusion: return "mascot-ex5a"
        case .letterToFriendThenSelf: return "mascot-ex6"
        case .matching: return "mascot-ex7"
        case .supportLetter: return "mascot-ex8"
        case .actionAndTime: return "mascot-ex9"
        case .values: return "mascot-ex10"
        case .multiSlider, .multiPartReflection, .ratingWithReflection: return "mascot-ex2"
        case .taggedThought: return "mascot-ex5a"
        case .freeTextWithTimePicker: return "mascot-ex9"
        }
    }

    private var lessonProgress: Double {
        guard !course.lessons.isEmpty else { return 0 }
        return Double(lesson.indexInCourse) / Double(course.lessons.count)
    }

    private var isAnswerEmpty: Bool {
        answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Урок \(lesson.indexInCourse) из \(course.lessons.count)")
                        .font(.lumi(11, weight: .bold))
                        .foregroundStyle(LumiColor.textTertiary)
                    Spacer()
                    LumiIcon(name: "icon-heart-fill", size: 15, fallbackSystemImage: "heart.fill")
                        .foregroundStyle(Color(hex: 0xFF7A94))
                }
                .padding(.bottom, 6)

                LumiProgressBar(progress: lessonProgress)
                    .padding(.bottom, 16)

                LumiMascot(assetName: mascotAssetName, size: 110)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)

                Text(lesson.title)
                    .font(.lumiScreenTitle(20))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)

                Text(lesson.explanation)
                    .font(.lumiBody)
                    .lumiRounded()
                    .foregroundStyle(LumiColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lumiCard(radius: 14)
                    .padding(.bottom, 20)

                Text(lesson.exercisePrompt)
                    .font(.lumiHeadline)
                    .lumiRounded()
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                ExercisePlayerView(kind: lesson.exerciseKind, prompt: lesson.exercisePrompt, answerText: $answerText)

                if !lesson.example.isEmpty && lesson.example != "TODO" {
                    Text("Пример: \(lesson.example)")
                        .font(.lumi(11.5, weight: .semibold))
                        .foregroundStyle(LumiColor.textFaint2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                }

                Spacer(minLength: 20)

                Button {
                    showCrisisSupport = true
                } label: {
                    Text("Мне сейчас правда тяжело →")
                        .font(.lumi(11, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 12)

                PrimaryButton(title: "Завершить", isEnabled: !isAnswerEmpty, action: submit)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        // Presented as a cover, not a push: dismissing it pops the finished
        // lesson too, so "Далее" lands back on Home/the course instead of
        // on the exercise the user just completed.
        .fullScreenCover(isPresented: $showCompletion, onDismiss: { dismiss() }) {
            LessonCompletionView(course: course, lesson: lesson)
        }
        .fullScreenCover(isPresented: $showCrisisSupport) {
            CrisisSupportView()
        }
    }

    private func submit() {
        if crisisDetector.isCrisisSignal(in: answerText) {
            // No XP/lumens/streak impact — gamification stops entirely for this interaction.
            showCrisisSupport = true
            return
        }

        let existing = progress ?? {
            let new = UserProgress()
            modelContext.insert(new)
            return new
        }()

        // Streak counts as "showed up today" even on a replay; XP/lumens
        // below must NOT re-trigger on replay — this used to let you
        // infinite-farm currency by resubmitting an already-completed lesson.
        let isFirstCompletion = !existing.completedLessonIDs.contains(lesson.id)
        StreakEngine.recordLessonCompletion(on: existing)

        if isFirstCompletion {
            existing.xp += GamificationRules.xpPerLesson
            existing.lumens += GamificationRules.lumensPerLesson
            existing.completedLessonIDs.append(lesson.id)
            if Calendar.current.component(.hour, from: .now) < 9 {
                existing.earlyBirdLessonCount += 1
            }

            let courseLessonIDs = Set(course.lessons.map(\.id))
            if courseLessonIDs.isSubset(of: Set(existing.completedLessonIDs)) {
                existing.lumens += GamificationRules.lumensBonusPerCourseCompletion
                advanceToNextCourse(existing)
            }

            notifyNewlyUnlockedAchievements(existing)
        }

        if remindersEnabled {
            NotificationScheduler.reschedule(hour: reminderHour, minute: reminderMinute, lastActiveDate: existing.lastActiveDate)
        }

        WidgetSync.refresh()
        showCompletion = true
    }

    private func notifyNewlyUnlockedAchievements(_ progress: UserProgress) {
        for achievement in AchievementCatalog.all
        where achievement.isUnlocked(progress) && !progress.notifiedAchievementIDs.contains(achievement.id) {
            progress.notifiedAchievementIDs.append(achievement.id)
            if remindersEnabled {
                NotificationScheduler.notifyAchievementUnlocked(achievement)
            }
        }
    }

    /// Home shows `currentCourseID`'s next incomplete lesson — without this,
    /// finishing a course's last lesson would leave Home stuck pointing at
    /// that same finished course forever.
    private func advanceToNextCourse(_ progress: UserProgress) {
        guard progress.currentCourseID == course.id else { return }
        let next = CourseCatalog.courses
            .filter { $0.number > course.number }
            .min { $0.number < $1.number }
        if let next {
            progress.currentCourseID = next.id
        }
    }
}

#Preview {
    NavigationStack {
        LessonPlayerView(course: CourseCatalog.courses[0], lesson: CourseCatalog.courses[0].lessons[0])
    }
    .preferredColorScheme(.dark)
    .modelContainer(PersistenceController.makePreviewContainer())
}
