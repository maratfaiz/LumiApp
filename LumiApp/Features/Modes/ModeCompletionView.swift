import SwiftData
import SwiftUI

/// Общий экран «практика завершена» для Дыхания / Аффирмаций / Медитации
/// (F26/F27/F29). Показывает ровно то, что реально начислено — включая
/// случай «сегодня награда уже была», без обвинительной формулировки.
struct ModeCompletionView: View {
    let title: String
    let subtitle: String
    let mascotAsset: String
    let reward: PracticeRewardLedger.Outcome
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

                rewardPill

                if case .rewardedWithExtraTask(_, let tokensLeft) = reward {
                    Text("Списано «Доп. задание дня» · осталось \(tokensLeft)")
                        .font(.lumi(11, weight: .semibold))
                        .foregroundStyle(LumiColor.textTertiary)
                }

                Spacer(minLength: 4)

                PrimaryButton(title: actionTitle, action: action)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var noRewardText: String {
        if case .dailyLimitReached(let limit) = reward {
            return "Сегодня уже \(limit) практики с наградой — завтра снова. Практика всё равно зачтена"
        }
        return "Люмены за эту практику сегодня уже начислены — но практика зачтена"
    }

    @ViewBuilder private var rewardPill: some View {
        switch reward {
        case .rewarded(let lumens), .rewardedWithExtraTask(let lumens, _):
            HStack(spacing: 6) {
                LumiIcon(name: "icon-lumen", size: 14, fallbackSystemImage: "star.fill")
                Text("+\(lumens) люменов")
            }
            .font(.lumi(13, weight: .heavy))
            .foregroundStyle(LumiColor.yellow)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(LumiColor.yellow.opacity(0.14)))
            .overlay(Capsule().stroke(LumiColor.yellow.opacity(0.3), lineWidth: 1))
        case .alreadyRewardedToday, .dailyLimitReached:
            Text(noRewardText)
                .font(.lumi(12, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(LumiColor.cardFillLight))
        }
    }
}

/// Честная подпись на экране практики: что будет начислено, если довести
/// сессию до конца.
struct PracticeRewardBadge: View {
    let practice: Practice
    let progress: UserProgress?

    var body: some View {
        switch PracticeRewardLedger.preview(practice, progress: progress) {
        case .rewarded(let lumens):
            badge(text: "+\(lumens) люменов за сессию", color: LumiColor.yellow, icon: "icon-lumen")
        case .rewardedWithExtraTask(let lumens, _):
            badge(text: "+\(lumens) люменов · доп. задание дня", color: LumiColor.blueChip, icon: "icon-plus")
        case .alreadyRewardedToday:
            badge(text: "Сегодня люмены уже получены", color: LumiColor.textSecondary, icon: "icon-clock")
        case .dailyLimitReached(let limit):
            badge(text: "Дневной лимит: \(limit) практики", color: LumiColor.textSecondary, icon: "icon-clock")
        }
    }

    private func badge(text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 5) {
            LumiIcon(name: icon, size: 11, fallbackSystemImage: "star.fill")
            Text(text)
        }
        .font(.lumi(11, weight: .bold))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

#Preview {
    ModeCompletionView(
        title: "Дыхание завершено",
        subtitle: "Ты сделал(а) 4 раунда 4-7-8. Тело и разум немного спокойнее",
        mascotAsset: "mascot-breathcomplete",
        reward: .rewarded(lumens: 15),
        action: {}
    )
    .preferredColorScheme(.dark)
}
