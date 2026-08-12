import SwiftUI

/// Экран «новый уровень». Раньше повышение уровня не сопровождалось ничем:
/// число в профиле молча менялось. Теперь у уровня есть звание и награда,
/// и их показывают в момент получения.
struct LevelUpView: View {
    let rewards: [LevelReward]
    let onDismiss: () -> Void

    private var top: LevelReward? { rewards.last }

    var body: some View {
        ZStack {
            LumiBackground()
            StarField(stars: StarPresets.celebration)

            VStack(spacing: 14) {
                Spacer(minLength: 20)

                Text("Новый уровень")
                    .font(.lumi(12, weight: .heavy))
                    .foregroundStyle(LumiColor.purpleLight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(LumiColor.purple1.opacity(0.16)))
                    .overlay(Capsule().stroke(LumiColor.purple1.opacity(0.4), lineWidth: 1))

                Text("\(top?.level ?? 1)")
                    .font(.lumiScreenTitle(64))
                    .foregroundStyle(Color.white)
                    .shadow(color: LumiColor.purple1.opacity(0.7), radius: 16)

                Text(top?.title ?? "")
                    .font(.lumiScreenTitle(22))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)

                LumiMascot(assetName: "mascot-ex9", size: 170, accessibilityTitle: "Луми празднует новый уровень")

                VStack(spacing: 8) {
                    ForEach(rewards, id: \.level) { reward in
                        ForEach(reward.rewardLines, id: \.self) { line in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(LumiColor.green)
                                Text(line)
                                    .font(.lumi(13, weight: .bold))
                                    .foregroundStyle(LumiColor.textBright)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lumiCard(fill: LumiColor.cardFillLight, radius: 12)
                        }
                    }
                }

                Spacer(minLength: 12)

                PrimaryButton(title: "Отлично", action: onDismiss)
            }
            .padding(20)
        }
    }
}

/// Плашка «открыто достижение» — показывается там же, где награда за урок.
struct AchievementUnlockedBanner: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 11) {
            Circle()
                .fill(AchievementStyle.color(for: achievement.id))
                .frame(width: 38, height: 38)
                .overlay(
                    LumiIcon(name: AchievementStyle.icon(for: achievement.id), size: 17, fallbackSystemImage: "rosette")
                        .foregroundStyle(Color(hex: 0x2A1A00))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text("Достижение: \(achievement.title)")
                    .font(.lumi(12.5, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .fixedSize(horizontal: false, vertical: true)
                if !achievement.rewardSummary.isEmpty {
                    Text(achievement.rewardSummary)
                        .font(.lumi(11, weight: .bold))
                        .foregroundStyle(LumiColor.yellow)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .lumiAccentCard(AchievementStyle.color(for: achievement.id), radius: 14)
    }
}

#Preview {
    LevelUpView(
        rewards: [LevelSystem.rewards[2]],
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
