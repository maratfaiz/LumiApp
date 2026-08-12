import SwiftUI

/// Техника «Фокус на ценностях» (ACT): выбрать ценность и одно маленькое
/// действие по ней на сегодня. Фокус сохраняется до конца дня — завтра
/// экран снова чистый, чтобы это не превращалось в накопительный список
/// невыполненного.
struct ValuesFocusView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("valuesFocusValue") private var savedValue = ""
    @AppStorage("valuesFocusAction") private var savedAction = ""
    @AppStorage("valuesFocusDay") private var savedDay = ""
    @AppStorage("valuesFocusDone") private var savedDone = false

    @State private var selectedValue: String?
    @State private var action = ""

    private let values = [
        "Забота о себе", "Честность", "Близость", "Развитие",
        "Смелость", "Спокойствие", "Творчество", "Помощь другим",
    ]

    private var today: String {
        PracticeRewardLedger.dayKey(.now)
    }

    private var hasTodayFocus: Bool {
        savedDay == today && !savedValue.isEmpty
    }

    var body: some View {
        LumiScreen {
            VStack(alignment: .leading, spacing: 16) {
                TechniqueHeader(
                    title: "Фокус на ценностях",
                    subtitle: "Ценность — это направление, а не цель. Достаточно одного маленького шага в её сторону.",
                    mascotAsset: "mascot-ex10",
                    mascotSize: 110
                )

                if hasTodayFocus {
                    todayCard
                } else {
                    picker
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if savedDay != today {
                savedValue = ""
                savedAction = ""
                savedDone = false
            }
        }
    }

    // MARK: Выбор

    private var picker: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Что сегодня важно")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(values, id: \.self) { value in
                    let isSelected = selectedValue == value
                    Button {
                        selectedValue = value
                    } label: {
                        Text(value)
                            .font(.lumi(12.5, weight: isSelected ? .heavy : .semibold))
                            .foregroundStyle(isSelected ? Color.white : LumiColor.textBody)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? LumiColor.purple1.opacity(0.22) : LumiColor.cardFillLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? LumiColor.purple1 : LumiColor.cardBorder, lineWidth: isSelected ? 2 : 1)
                    )
                }
            }

            SectionLabel(text: "Один маленький шаг сегодня")
            ZStack(alignment: .topLeading) {
                TextEditor(text: $action)
                    .font(.lumi(13, weight: .semibold))
                    .padding(8)
                    .frame(height: 90)
                    .lumiInputField()
                if action.isEmpty {
                    Text("Например: лечь спать до 23:00")
                        .font(.lumi(13, weight: .semibold))
                        .foregroundStyle(LumiColor.textDim)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            PrimaryButton(
                title: "Сохранить на сегодня",
                isEnabled: selectedValue != nil && !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                savedValue = selectedValue ?? ""
                savedAction = action.trimmingCharacters(in: .whitespacesAndNewlines)
                savedDay = today
                savedDone = false
            }
        }
    }

    // MARK: Сегодняшний фокус

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "Ценность дня", color: LumiColor.purpleLight)
                Text(savedValue)
                    .font(.lumi(18, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text(savedAction)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lumiAccentCard(LumiColor.purple1)

            Button {
                savedDone.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: savedDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(savedDone ? LumiColor.green : LumiColor.textDim)
                    Text(savedDone ? "Шаг сделан" : "Отметить, когда получится")
                        .font(.lumi(13, weight: .bold))
                        .foregroundStyle(savedDone ? LumiColor.green : LumiColor.textBright)
                    Spacer(minLength: 0)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .background(RoundedRectangle(cornerRadius: 14).fill(LumiColor.cardFillLight))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LumiColor.cardBorder, lineWidth: 1))

            Text("Не получилось — тоже нормально. Ценность никуда не денется, шаг можно повторить завтра.")
                .font(.lumi(11.5, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            TextLinkButton(title: "Выбрать другую ценность") {
                savedValue = ""
                savedAction = ""
                savedDone = false
                selectedValue = nil
                action = ""
            }
        }
    }
}

#Preview {
    NavigationStack { ValuesFocusView() }
        .preferredColorScheme(.dark)
}
