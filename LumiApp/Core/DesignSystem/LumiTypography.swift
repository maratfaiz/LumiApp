import SwiftUI

extension Font {
    /// Fixed-size rounded system font, standing in for the design's Nunito
    /// typeface. Used for compact chrome (chips, tab bar, captions inside
    /// cards) where the design's exact proportions matter.
    ///
    /// Long-form copy — lesson text, exercise prompts, disclaimers — keeps
    /// the Dynamic Type styles below instead, so the accessibility
    /// requirement in Lumi_PRD.pdf §8 still holds where it matters most.
    static func lumi(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Screen title ("Профиль", "Магазин", …) — the design's 22–26pt black
    /// rounded heading.
    static func lumiScreenTitle(_ size: CGFloat = 24) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }

    // Dynamic Type styles, now rounded to match the design's typeface.
    static let lumiTitle = Font.title.weight(.black)
    static let lumiHeadline = Font.headline
    static let lumiBody = Font.body
    static let lumiCaption = Font.caption
}

extension View {
    /// Applies the design's rounded typeface to a Dynamic Type style.
    func lumiRounded() -> some View {
        fontDesign(.rounded)
    }
}
