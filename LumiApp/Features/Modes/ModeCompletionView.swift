import SwiftUI

/// Shared "practice finished" screen for Дыхание / Аффирмации / Медитация
/// (F26/F27/F29), ported from the design's completion screens: title,
/// mascot, lumens reward pill, single CTA.
struct ModeCompletionView: View {
    let title: String
    let subtitle: String
    let mascotAsset: String
    var actionTitle: String = "Готово"
    let action: () -> Void

    var body: some View {
        LumiScreen(stars: StarPresets.celebration) {
            VStack(spacing: 14) {
                Spacer(minLength: 4)

                Text(title)
                    .font(.lumiScreenTitle(24))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)

                LumiMascot(assetName: mascotAsset, size: 170, accessibilityTitle: "Луми радуется вместе с тобой")
                    .padding(.vertical, 8)

                HStack(spacing: 6) {
                    LumiIcon(name: "icon-lumen", size: 14, fallbackSystemImage: "star.fill")
                    Text("+\(GamificationRules.lumensPerModeSession) люменов")
                }
                .font(.lumi(13, weight: .heavy))
                .foregroundStyle(LumiColor.yellow)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(LumiColor.yellow.opacity(0.14)))
                .overlay(Capsule().stroke(LumiColor.yellow.opacity(0.3), lineWidth: 1))

                Spacer(minLength: 4)

                PrimaryButton(title: actionTitle, action: action)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ModeCompletionView(
        title: "Дыхание завершено",
        subtitle: "Ты сделал(а) 4 раунда 4-7-8. Тело и разум немного спокойнее",
        mascotAsset: "mascot-breathcomplete",
        action: {}
    )
    .preferredColorScheme(.dark)
}
