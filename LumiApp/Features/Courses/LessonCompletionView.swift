import SwiftUI

/// F9 — reward + mascot success reaction, shown before the user can move on.
struct LessonCompletionView: View {
    let course: Course
    let lesson: Lesson
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image("mascot-lessoncomplete")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
            Text(lesson.mascotMessage.isEmpty || lesson.mascotMessage == "TODO"
                 ? "Отличная работа!"
                 : lesson.mascotMessage)
                .font(.lumiHeadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if !lesson.result.isEmpty && lesson.result != "TODO" {
                Text(lesson.result)
                    .font(.lumiCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Text("+\(GamificationRules.xpPerLesson) XP · +\(GamificationRules.lumensPerLesson) люменов")
                .font(.lumiBody)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Продолжить") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
                .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    LessonCompletionView(course: CourseCatalog.courses[0], lesson: CourseCatalog.courses[0].lessons[0])
}
