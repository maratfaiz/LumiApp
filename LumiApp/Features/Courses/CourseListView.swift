import SwiftData
import SwiftUI

/// F6 — courses shown as done / current / locked. Courses are strictly
/// sequential in the order determined by the onboarding track; jumping
/// ahead (even via deep link) must stay impossible (Acceptance Criteria).
/// Layout ported from the design's `is.catalog` screen.
struct CourseListView: View {
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private enum CourseState { case completed, current, locked }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Курсы")
                        .font(.lumiScreenTitle(26))
                        .foregroundStyle(Color.white)
                    Text("Твой путь к уверенности")
                        .font(.lumi(12, weight: .semibold))
                        .foregroundStyle(LumiColor.textSecondary)
                }

                progressCard

                SectionLabel(text: "Мои курсы")

                VStack(spacing: 10) {
                    ForEach(CourseCatalog.courses) { course in
                        courseRow(course)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Course.self) { course in
            CourseDetailView(course: course)
        }
    }

    // MARK: Overall progress

    private var completedCourses: Int {
        CourseCatalog.courses.filter { state(for: $0) == .completed }.count
    }

    private var overallProgress: Double {
        guard !CourseCatalog.courses.isEmpty else { return 0 }
        return Double(completedCourses) / Double(CourseCatalog.courses.count)
    }

    private var progressCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: CGFloat(overallProgress))
                    .stroke(LumiColor.purple1, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(overallProgress * 100))%")
                    .font(.lumi(11, weight: .heavy))
                    .foregroundStyle(Color.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                SectionLabel(text: "Твой прогресс", color: LumiColor.purpleLight)
                Text("\(completedCourses) из \(CourseCatalog.courses.count) курсов пройдено")
                    .font(.lumi(13, weight: .heavy))
                    .foregroundStyle(Color.white)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .lumiAccentCard(LumiColor.purple1)
    }

    // MARK: Rows

    @ViewBuilder
    private func courseRow(_ course: Course) -> some View {
        let state = state(for: course)
        let row = HStack(spacing: 13) {
            ZStack {
                Circle().fill(Color.white.opacity(0.08)).frame(width: 44, height: 44)
                LumiGlyph(name: icon(for: course), size: 17)
                    .foregroundStyle(state == .current ? Color.white : LumiColor.textBody)
            }
            .opacity(state == .locked ? 0.6 : 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Курс \(course.number) · \(course.title)")
                    .font(.lumi(13, weight: state == .current ? .heavy : .bold))
                    .foregroundStyle(state == .current ? Color.white : LumiColor.textBody)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle(for: course, state: state))
                    .font(.lumi(10, weight: .semibold))
                    .foregroundStyle(LumiColor.textFaint2)
                if state == .current {
                    LumiProgressBar(progress: completion(for: course), height: 5)
                }
            }

            Spacer(minLength: 0)
            trailing(for: course, state: state)
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(state == .current ? LumiColor.purple1.opacity(0.18) : Color.white.opacity(state == .locked ? 0.02 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    state == .current ? LumiColor.purple1 : Color.white.opacity(state == .locked ? 0.14 : 0.1),
                    style: StrokeStyle(
                        lineWidth: state == .current ? 2 : (state == .locked ? 1.5 : 1),
                        dash: state == .locked ? [4] : []
                    )
                )
        )

        if state == .locked {
            row.accessibilityHint("Курс заблокирован")
        } else {
            NavigationLink(value: course) { row }
                .buttonStyle(.lumiPlain)
        }
    }

    @ViewBuilder
    private func trailing(for course: Course, state: CourseState) -> some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(LumiColor.purple1)
        case .current:
            Text("\(Int(completion(for: course) * 100))%")
                .font(.lumi(11, weight: .bold))
                .foregroundStyle(LumiColor.purpleLight)
        case .locked:
            LumiIcon(name: "icon-lock", size: 12, fallbackSystemImage: "lock.fill")
                .foregroundStyle(LumiColor.textFaint2)
        }
    }

    private func subtitle(for course: Course, state: CourseState) -> String {
        let lessons = RussianPlural.lessons(course.lessons.count)
        switch state {
        case .completed: return "\(lessons) · пройден"
        case .current: return "\(lessons) · сейчас"
        case .locked: return "\(lessons) · заблокирован"
        }
    }

    /// Uses the mascot-free Phosphor set so each course reads differently
    /// in the list, as in the design's catalog mock-up.
    private func icon(for course: Course) -> String {
        switch course.number {
        case 0: return "star.fill"
        case 1: return "icon-critic-voice"
        case 2: return "icon-heart-fill"
        case 5: return "icon-seal"
        default: return "icon-book"
        }
    }

    private func completion(for course: Course) -> Double {
        guard let progress, !course.lessons.isEmpty else { return 0 }
        let done = course.lessons.filter { progress.completedLessonIDs.contains($0.id) }.count
        return Double(done) / Double(course.lessons.count)
    }

    private func state(for course: Course) -> CourseState {
        guard let progress else { return course.number == 0 ? .current : .locked }
        if course.id == progress.currentCourseID { return .current }
        let lessonIDs = Set(course.lessons.map(\.id))
        if !lessonIDs.isEmpty, lessonIDs.isSubset(of: Set(progress.completedLessonIDs)) { return .completed }
        return .locked
    }
}

#Preview {
    NavigationStack { CourseListView() }
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
