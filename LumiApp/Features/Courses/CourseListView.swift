import SwiftData
import SwiftUI

/// F6 — courses shown as done / current / locked. Courses are strictly
/// sequential in the order determined by the onboarding track; jumping
/// ahead (even via deep link) must stay impossible (Acceptance Criteria).
struct CourseListView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    var body: some View {
        NavigationStack {
            List(CourseCatalog.courses) { course in
                NavigationLink(value: course) {
                    CourseRow(course: course, state: state(for: course))
                }
                .disabled(state(for: course) == .locked)
            }
            .navigationTitle("Курсы")
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
        }
    }

    private enum CourseState { case completed, current, locked }

    private func state(for course: Course) -> CourseState {
        guard let progress else { return course.number == 0 ? .current : .locked }
        if course.id == progress.currentCourseID { return .current }
        let lessonIDs = Set(course.lessons.map(\.id))
        if lessonIDs.isSubset(of: Set(progress.completedLessonIDs)) { return .completed }
        return .locked
    }

    private struct CourseRow: View {
        let course: Course
        let state: CourseState

        var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(course.title).font(.lumiBody.bold())
                    Text(course.summary).font(.lumiCaption).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                icon
            }
        }

        @ViewBuilder private var icon: some View {
            switch state {
            case .completed: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            case .current: Image(systemName: "play.circle.fill").foregroundStyle(LumiColor.accent)
            case .locked: Image(systemName: "lock.fill").foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    CourseListView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
