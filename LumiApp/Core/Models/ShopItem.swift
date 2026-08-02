import Foundation

enum ShopItemKind: String, Codable {
    case streakFreeze
    case mascotSkin
    case secretTechnique
}

/// Shop inventory is cosmetic/convenience only — nothing here may speed up
/// course progress (see the pay-to-win prohibition in Lumi_MVP_Scope.docx).
struct ShopItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let kind: ShopItemKind
    let priceLumens: Int
}
