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
        let dialNumber: String // digits only, for the tel: link
    }

    private let helplines: [Helpline] = [
        Helpline(country: "Россия", name: "Детский телефон доверия", number: "8 800 2000 122", dialNumber: "88002000122"),
        Helpline(country: "Россия", name: "Кризисная линия для взрослых", number: "8 800 333-44-34", dialNumber: "88003334434"),
        Helpline(country: "Казахстан", name: "Единая национальная линия поддержки", number: "111", dialNumber: "111"),
        Helpline(country: "Беларусь", name: "Детская телефонная линия", number: "8 801 100-16-11", dialNumber: "88011001611"),
        Helpline(country: "Беларусь", name: "Экстренная психологическая помощь", number: "133", dialNumber: "133"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MascotView(state: .innerCritic)
                        .frame(width: 100, height: 100)
                        .frame(maxWidth: .infinity)

                    Text("То, что ты сейчас чувствуешь — серьёзно, и с этим не нужно справляться в одиночку.")
                        .font(.lumiBody)
                        .multilineTextAlignment(.center)

                    ForEach(helplines) { line in
                        Link(destination: URL(string: "tel:\(line.dialNumber)")!) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(line.country) · \(line.name)").font(.lumiCaption).foregroundStyle(.secondary)
                                    Text(line.number).font(.lumiBody.bold())
                                }
                                Spacer()
                                Image(systemName: "phone.fill")
                            }
                            .padding(12)
                            .background(LumiColor.accentSoft, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .tint(.primary)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        // No XP/streak/reward UI anywhere on this screen — gamification is
        // fully suspended for this interaction (Lumi_Crisis_Protocol.docx §2).
    }
}

#Preview {
    CrisisSupportView()
}
