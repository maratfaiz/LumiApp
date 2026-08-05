import SwiftData
import SwiftUI

/// F7 — the 5 lessons of a course, shown in strict order.
struct CourseDetailView: View {
    let course: Course
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        List(course.lessons) { lesson in
            NavigationLink(value: lesson) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title).font(.lumiBody)
                        if !lesson.goal.isEmpty && lesson.goal != "TODO" {
                            Text(lesson.goal)
                                .font(.lumiCaption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    if let progress, progress.completedLessonIDs.contains(lesson.id) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    }
                }
            }
            .disabled(!isUnlocked(lesson))
        }
        .navigationTitle(course.title)
        .navigationDestination(for: Lesson.self) { lesson in
            LessonPlayerView(course: course, lesson: lesson)
        }
    }

    private func isUnlocked(_ lesson: Lesson) -> Bool {
        guard let progress else { return lesson.indexInCourse == 1 }
        if progress.completedLessonIDs.contains(lesson.id) { return true }
        guard let previous = course.lessons.first(where: { $0.indexInCourse == lesson.indexInCourse - 1 }) else {
            return true // first lesson
        }
        return progress.completedLessonIDs.contains(previous.id)
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: CourseCatalog.courses[0])
    }
    .modelContainer(PersistenceController.makePreviewContainer())
}
