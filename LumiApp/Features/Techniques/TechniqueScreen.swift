import SwiftUI

/// Роутер «секретных техник» из магазина: покупка открывает не строчку в
/// инвентаре, а работающую практику. Список техник — в `ShopCatalog`.
struct TechniqueScreen: View {
    let item: ShopItem

    var body: some View {
        switch item.id {
        case ShopCatalog.selfEmbraceID:
            SelfEmbraceView()
        case ShopCatalog.emotionDiaryID:
            EmotionDiaryView()
        case ShopCatalog.valuesFocusID:
            ValuesFocusView()
        default:
            LumiScreen {
                Text("Эта техника пока не открыта.")
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textSecondary)
            }
        }
    }
}

/// Общая шапка практики: заголовок, пояснение и маскот.
struct TechniqueHeader: View {
    let title: String
    let subtitle: String
    var mascotAsset: String = "mascot-meditation"
    var mascotSize: CGFloat = 120

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.lumiScreenTitle(22))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.lumi(12.5, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            LumiMascot(assetName: mascotAsset, size: mascotSize)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }
}
