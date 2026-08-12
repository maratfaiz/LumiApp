import SwiftData
import SwiftUI

/// The design's "Серия начата!" celebration, shown once — right after the
/// first lesson that starts a streak. Framing is deliberately non-punitive
/// (Lumi_Gamification_Economy.docx): a missed day is explicitly called out
/// as fine, protected by a freeze.
struct StreakStartView: View {
    let onDismiss: () -> Void

    @Query private var progresses: [UserProgress]
    private var progress: UserProgress? { progresses.first }

    private let weekdayLabels = ["П", "В", "С", "Ч", "П", "С", "В"]

    var body: some View {
        ZStack {
            LumiBackground()
            StarField(stars: StarPresets.streak)

            VStack(spacing: 0) {
                Text("НОВАЯ СЕРИЯ")
                    .font(.lumi(12, weight: .heavy))
                    .foregroundStyle(LumiColor.orange1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LumiColor.orange1.opacity(0.14)))
                    .overlay(Capsule().stroke(LumiColor.orange1.opacity(0.35), lineWidth: 1))
                    .padding(.top, 50)
                    .padding(.bottom, 22)

                (Text("Серия ").foregroundColor(.white) + Text("начата!").foregroundColor(LumiColor.orange1))
                    .font(.lumiScreenTitle(22))
                    .padding(.bottom, 26)

                LumiProgressRing(
                    progress: 1.0 / 7.0,
                    diameter: 140,
                    lineWidth: 9,
                    tint: AnyShapeStyle(LumiGradient.streak),
                    glow: LumiColor.orange1
                ) {
                    VStack(spacing: 2) {
                        LumiIcon(name: "icon-streak", size: 28, fallbackSystemImage: "flame.fill")
                            .foregroundStyle(LumiColor.orange1)
                        Text("\(progress?.currentStreakDays ?? 1)")
                            .font(.lumiScreenTitle(36))
                            .foregroundStyle(Color.white)
                    }
                }
                .padding(.bottom, 26)

                HStack(spacing: 7) {
                    ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.lumi(11, weight: .heavy))
                            .foregroundStyle(index == 0 ? Color.white : Color(hex: 0x5F5580))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(index == 0 ? AnyShapeStyle(LumiGradient.streak) : AnyShapeStyle(LumiColor.cardFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(index == 0 ? 0 : 0.1), lineWidth: 1)
                            )
                    }
                }
                .padding(.bottom, 24)

                Text("Каждый день практики продолжает её.\nПропуск не страшен — заморозка защитит серию.")
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                Spacer()

                PrimaryButton(title: "Понятно, погнали!", action: onDismiss)
            }
            .padding(20)
        }
    }
}

#Preview {
    StreakStartView(onDismiss: {})
        .preferredColorScheme(.dark)
        .modelContainer(PersistenceController.makePreviewContainer())
}
