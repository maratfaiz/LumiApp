import SwiftUI

/// F18 — shown automatically when CrisisDetector fires, and always reachable
/// from Settings. Numbers are from Lumi_Crisis_Protocol.docx §4 and MUST be
/// re-verified before every release (§5) — that check belongs in the release
/// checklist, not just in this file.
struct CrisisSupportView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Helpline: Identifiable {
        let id = UUID()
        let country: String
        let name: String
        let number: String
        /// digits only, for the tel: link
        let dialNumber: String
        let icon: String
        let color: Color
    }

    private let helplines: [Helpline] = [
        Helpline(country: "Россия", name: "Детский телефон доверия", number: "8 800 2000 122", dialNumber: "88002000122", icon: "icon-call", color: LumiColor.blueChip),
        Helpline(country: "Россия", name: "Кризисная линия для взрослых", number: "8 800 333-44-34", dialNumber: "88003334434", icon: "icon-message", color: LumiColor.purpleLight),
        Helpline(country: "Казахстан", name: "Единая национальная линия поддержки", number: "111", dialNumber: "111", icon: "icon-call", color: LumiColor.blueChip),
        Helpline(country: "Беларусь", name: "Детская телефонная линия", number: "8 801 100-16-11", dialNumber: "88011001611", icon: "icon-call", color: LumiColor.purpleLight),
        Helpline(country: "Беларусь", name: "Экстренная психологическая помощь", number: "133", dialNumber: "133", icon: "cross.case.fill", color: LumiColor.orange1),
    ]

    var body: some View {
        NavigationStack {
            LumiScreen {
                VStack(spacing: 14) {
                    VStack(spacing: 10) {
                        LumiMascot(assetName: "mascot-crisis", size: 96, accessibilityTitle: "Луми рядом")
                        Text("Тебе сейчас тяжело?")
                            .font(.lumiScreenTitle(19))
                            .foregroundStyle(Color.white)
                        Text("То, что ты сейчас чувствуешь — серьёзно, и с этим не нужно справляться в одиночку. Я не могу заменить живого специалиста, но рядом есть люди, которые умеют помочь прямо сейчас.")
                            .font(.lumi(13, weight: .semibold))
                            .foregroundStyle(LumiColor.textBody)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(15)
                            .lumiCard(radius: 14)
                    }

                    ForEach(helplines) { line in
                        Link(destination: URL(string: "tel:\(line.dialNumber)")!) {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle().fill(line.color.opacity(0.2)).frame(width: 34, height: 34)
                                    LumiGlyph(name: line.icon, size: 14).foregroundStyle(line.color)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(line.country) · \(line.name)")
                                        .font(.lumi(13, weight: .heavy))
                                        .foregroundStyle(Color.white)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(line.number)
                                        .font(.lumi(12, weight: .semibold))
                                        .foregroundStyle(line.color)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(13)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lumiAccentCard(line.color, radius: 14)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        LumiMascot(assetName: "mascot-home", size: 36)
                        Text("Ты важен(на). Тебя слышат. Ты не один(на).")
                            .font(.lumi(12, weight: .semibold))
                            .foregroundStyle(LumiColor.textBody)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(13)
                    .lumiCard(fill: LumiColor.cardFillFaint, border: Color.white.opacity(0.08))

                    Spacer(minLength: 8)

                    PrimaryButton(title: "Вернуться") { dismiss() }

                    Text("Можно просто побыть здесь")
                        .font(.lumi(11, weight: .semibold))
                        .foregroundStyle(LumiColor.textDim)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                        .font(.lumi(13, weight: .bold))
                }
            }
        }
        // No XP/streak/reward UI anywhere on this screen — gamification is
        // fully suspended for this interaction (Lumi_Crisis_Protocol.docx §2).
    }
}

#Preview {
    CrisisSupportView()
        .preferredColorScheme(.dark)
}
