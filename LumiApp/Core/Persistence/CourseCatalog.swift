import Foundation

/// Course/lesson metadata seeded from docs/product/Lumi_Course_Content.docx.
/// Only titles that are verbatim in that document are filled in below —
/// everything else is a TODO stub so nobody ships fabricated lesson copy.
/// TODO: replace this hardcoded catalog with a proper import step (e.g. a
/// build-time script that parses Lumi_Course_Content.docx into JSON) once
/// content is finalized — courses 2 and 5 aren't transcribed here yet.
/// All 10 F8 exercise mechanics are implemented (ExercisePlayerView.swift)
/// and ready to assign per-lesson via `Lesson.exerciseKind`; every stub
/// lesson here still defaults to `.freeText` since no real content exists
/// yet to justify picking one mechanic over another for it.
enum CourseCatalog {
    static let courses: [Course] = [
        Course(
            id: "course-0",
            number: 0,
            title: "Основы самооценки",
            summary: "Базовая психообразовательная модель: самооценка формируется опытом, а не является фиксированной чертой.",
            lessons: [
                stubLesson(course: 0, index: 1, title: "Что такое самооценка"),
                stubLesson(course: 0, index: 2, title: "Три источника самооценки"),
                stubLesson(course: 0, index: 3, title: "Мысли не равны фактам"),
                stubLesson(course: 0, index: 4, title: "Маленькие действия меняют самооценку"),
                stubLesson(course: 0, index: 5, title: "Твой план на ближайшие недели"),
            ]
        ),
        Course(
            id: "course-1",
            number: 1,
            title: "Работа с внутренним критиком",
            summary: "Замечать внутреннего критика как отдельный «голос», а не факт о себе, и мягко его оспаривать.",
            lessons: [
                stubLesson(course: 1, index: 1, title: "Знакомство с критиком"),
                stubLesson(course: 1, index: 2, title: "Критик говорит не фактами"),
                stubLesson(course: 1, index: 3, title: "Голос вместо истины"),
                stubLesson(course: 1, index: 4, title: "TODO: заголовок урока 1.4"),
                stubLesson(course: 1, index: 5, title: "TODO: заголовок урока 1.5"),
            ]
        ),
        Course(
            id: "course-2",
            number: 2,
            title: "Самосострадание",
            summary: "Есть клиническое примечание: у части пользователей возможен «страх самосострадания» — урок 2.1 вводится мягко.",
            lessons: (1...5).map { stubLesson(course: 2, index: $0, title: "TODO: заголовок урока 2.\($0)") }
        ),
        Course(
            id: "course-5",
            number: 5,
            title: "Самопринятие",
            summary: "Готов, принят. Есть 1 точечная правка, внесённая при финальной сверке.",
            lessons: (1...5).map { stubLesson(course: 5, index: $0, title: "TODO: заголовок урока 5.\($0)") }
        ),
    ]

    private static func stubLesson(course: Int, index: Int, title: String) -> Lesson {
        Lesson(
            id: "lesson-\(course)-\(index)",
            indexInCourse: index,
            title: title,
            goal: "TODO",
            explanation: "TODO",
            exercisePrompt: "TODO",
            example: "TODO",
            mascotMessage: "TODO"
        )
    }
}
