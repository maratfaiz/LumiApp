import SwiftData
import SwiftUI

/// F8 — explanation → exercise (free text here; some lessons use choice/slider
/// per the spec, add variants as content requires it) → example. On submit,
/// user text is checked against the crisis detector *before* anything else
/// happens — a crisis match must short-circuit straight to CrisisSupportView
/// with zero rewards granted (Lumi_Crisis_Protocol.docx §2).
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

    private let crisisDetector = CrisisDetector()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(lesson.title).font(.lumiTitle)
                Text(lesson.explanation).font(.lumiBody)

                Text(lesson.exercisePrompt).font(.lumiHeadline)
                ExercisePlayerView(kind: lesson.exerciseKind, prompt: lesson.exercisePrompt, answerText: $answerText)

                if !lesson.example.isEmpty && lesson.example != "TODO" {
                    Text("Пример: \(lesson.example)")
                        .font(.lumiCaption)
                        .foregroundStyle(.secondary)
                }

                Button("Завершить", action: submit)
                    .buttonStyle(.borderedProminent)
                    .tint(LumiColor.accent)
                    .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationDestination(isPresented: $showCompletion) {
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
        existing.xp += GamificationRules.xpPerLesson
        existing.lumens += GamificationRules.lumensPerLesson
        if !existing.completedLessonIDs.contains(lesson.id) {
            existing.completedLessonIDs.append(lesson.id)
        }
        StreakEngine.recordLessonCompletion(on: existing)
        if Calendar.current.component(.hour, from: .now) < 9 {
            existing.earlyBirdLessonCount += 1
        }
        if Set(course.lessons.map(\.id)).isSubset(of: Set(existing.completedLessonIDs)) {
            existing.lumens += GamificationRules.lumensBonusPerCourseCompletion
        }

        showCompletion = true
    }
}

#Preview {
    NavigationStack {
        LessonPlayerView(course: CourseCatalog.courses[0], lesson: CourseCatalog.courses[0].lessons[0])
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
