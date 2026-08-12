import SwiftData
import SwiftUI

/// F7 — the 5 lessons of a course, shown in strict order. Layout ported
/// from the design's course page (`is.catalogDetail`).
struct CourseDetailView: View {
    let course: Course
    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private var completedCount: Int {
        guard let progress else { return 0 }
        return course.lessons.filter { progress.completedLessonIDs.contains($0.id) }.count
    }

    private var completion: Double {
        guard !course.lessons.isEmpty else { return 0 }
        return Double(completedCount) / Double(course.lessons.count)
    }

    private var nextLesson: Lesson? {
        course.lessons.first { !(progress?.completedLessonIDs.contains($0.id) ?? false) }
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Курс \(course.number)")
                        .font(.lumi(12, weight: .bold))
                        .foregroundStyle(LumiColor.textSecondary)
                    Spacer()
                    if let progress {
                        HStack(spacing: 4) {
                            LumiIcon(name: "icon-lumen", size: 13, fallbackSystemImage: "star.fill")
                            Text("\(progress.lumens)")
                        }
                        .font(.lumi(12, weight: .heavy))
                        .foregroundStyle(LumiColor.yellow)
                    }
                }

                Text(course.title)
                    .font(.lumiScreenTitle(18))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(RussianPlural.lessons(course.lessons.count))
                    .font(.lumi(11, weight: .semibold))
                    .foregroundStyle(LumiColor.textTertiary)

                LumiMascot(assetName: "mascot-coursepage", size: 150)
                    .frame(maxWidth: .infinity)

                Text(course.summary)
                    .font(.lumi(12, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lumiCard(radius: 14)

                HStack {
                    Text("Прогресс курса")
                    Spacer()
                    Text("\(Int(completion * 100))%")
                }
                .font(.lumi(11, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
                .padding(.top, 6)

                LumiProgressBar(progress: completion)

                VStack(spacing: 8) {
                    ForEach(course.lessons) { lesson in
                        lessonRow(lesson)
                    }
                }
                .padding(.top, 8)

                if let nextLesson {
                    NavigationLink(destination: LessonPlayerView(course: course, lesson: nextLesson)) {
                        Text(completedCount == 0 ? "Начать урок →" : "Продолжить урок →")
                            .font(.lumi(15, weight: .heavy))
                            .foregroundStyle(Color.white)
                            .lumiPrimaryButtonSurface()
                    }
                    .buttonStyle(.lumiPlain)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Lesson.self) { lesson in
            LessonPlayerView(course: course, lesson: lesson)
        }
    }

    @ViewBuilder
    private func lessonRow(_ lesson: Lesson) -> some View {
        let isDone = progress?.completedLessonIDs.contains(lesson.id) ?? false
        let isActive = !isDone && lesson.id == nextLesson?.id
        let isLocked = !isDone && !isActive

        let row = HStack {
            Text("\(lesson.indexInCourse). \(lesson.title)")
                .font(.lumi(12, weight: isActive ? .bold : .semibold))
                .foregroundStyle(isLocked ? LumiColor.textDim : (isActive ? Color.white : LumiColor.textBody))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(LumiColor.purple1)
            } else if isActive {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
            } else {
                LumiIcon(name: "icon-lock", size: 12, fallbackSystemImage: "lock.fill")
                    .foregroundStyle(LumiColor.textDim)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? LumiColor.purple1.opacity(0.18) : Color.white.opacity(isLocked ? 0.03 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? LumiColor.purple1 : Color.white.opacity(isLocked ? 0.06 : 0.1),
                    lineWidth: isActive ? 2 : 1
                )
        )

        if isLocked {
            row.accessibilityHint("Урок заблокирован")
        } else {
            NavigationLink(value: lesson) { row }
                .buttonStyle(.lumiPlain)
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: CourseCatalog.courses[0])
    }
    .preferredColorScheme(.dark)
    .modelContainer(PersistenceController.makePreviewContainer())
}
