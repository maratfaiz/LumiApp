import SwiftUI

enum LumiGradient {
    /// The design's `linear-gradient(135deg, #8b6cf6, #6c4fe0)` CTA fill.
    static let primary = LinearGradient(
        colors: [LumiColor.purple1, LumiColor.purple2],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let streak = LinearGradient(
        colors: [LumiColor.orange1, LumiColor.orange2],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    /// Deep space background with the glow anchored near the top-leading
    /// corner, exactly as in the prototype.
    static let background = RadialGradient(
        colors: [LumiColor.bgGlow, LumiColor.bgDeep],
        center: UnitPoint(x: 0.2, y: 0.0),
        startRadius: 0,
        endRadius: 520
    )
}

/// Full-bleed app background. Every screen sits on this.
struct LumiBackground: View {
    var body: some View {
        ZStack {
            LumiColor.bgDeep
            LumiGradient.background
        }
        .ignoresSafeArea()
    }
}

/// Shared chrome for every screen pushed onto a `NavigationStack`:
/// background, optional star field, and the design's 20pt content padding.
///
/// The `GeometryReader`-backed minimum height keeps `Spacer()`-based
/// centering working on short screens while still scrolling the ones that
/// overflow — the design's `overflow-y: auto` content area.
struct LumiScreen<Content: View>: View {
    var stars: [StarField.Spec]?
    var horizontalPadding: CGFloat
    var content: Content

    init(
        stars: [StarField.Spec]? = nil,
        horizontalPadding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.stars = stars
        self.horizontalPadding = horizontalPadding
        self.content = content()
    }

    var body: some View {
        ZStack {
            LumiBackground()
            if let stars {
                StarField(stars: stars)
            }
            GeometryReader { geo in
                ScrollView {
                    content
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: geo.size.height, alignment: .top)
                }
            }
        }
        .lumiNavigationChrome()
    }
}

/// A screen that fills the viewport without scrolling (splash, onboarding
/// questions, celebration screens) — the design's fixed-height layouts.
struct LumiFixedScreen<Content: View>: View {
    var stars: [StarField.Spec]?
    var content: Content

    init(stars: [StarField.Spec]? = nil, @ViewBuilder content: () -> Content) {
        self.stars = stars
        self.content = content()
    }

    var body: some View {
        ZStack {
            LumiBackground()
            if let stars {
                StarField(stars: stars)
            }
            content
                .padding(20)
        }
        .lumiNavigationChrome()
    }
}

extension View {
    /// Transparent navigation bar over the cosmic background, with the
    /// design's title/back-button colors.
    func lumiNavigationChrome() -> some View {
        self
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(LumiColor.purpleLight)
    }

    /// Dark-appropriate text field / editor surface: the design's
    /// `rgba(255,255,255,0.04)` fill with a hairline border.
    func lumiInputField(radius: CGFloat = 12) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LumiColor.cardFillFaint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(LumiColor.cardBorder, lineWidth: 1)
            )
            .foregroundStyle(LumiColor.textPrimary)
            .tint(LumiColor.purple1)
    }
}
