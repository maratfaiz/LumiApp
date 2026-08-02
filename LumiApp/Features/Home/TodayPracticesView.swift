import SwiftUI

/// "Сегодня для тебя" — 4 short practices separate from the structured
/// courses, added to docs/product/Lumi_Course_Content.docx. Not clinical
/// techniques, no forced completion (see the doc's §6 safety check).
struct TodayPracticesView: View {
    private let practices: [(title: String, subtitle: String, icon: String)] = [
        ("Практика", "Назови один подтверждённый факт о себе за сегодня", "checkmark.circle"),
        ("Дневник", "Запиши, за что ты благодарен себе сегодня", "book"),
        ("Дыхание", "Вдох на 4 счёта → задержка → выдох на 4, 3 круга", "wind"),
        ("Аффирмация", "«Я стараюсь, и это уже успех»", "text.quote"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сегодня для тебя")
                .font(.lumiHeadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(practices, id: \.title) { practice in
                HStack {
                    Image(systemName: practice.icon)
                        .foregroundStyle(LumiColor.accent)
                    VStack(alignment: .leading) {
                        Text(practice.title).font(.lumiBody.bold())
                        Text(practice.subtitle).font(.lumiCaption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    TodayPracticesView().padding()
}
