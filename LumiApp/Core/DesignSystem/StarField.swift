import SwiftUI

/// Decorative twinkling sparkles scattered over a screen, matching the
/// design's `@keyframes lumiTwinkle` star field.
struct StarField: View {
    struct Spec {
        let size: CGFloat
        let color: Color
        /// Position as a fraction (0...1) of the container's width/height.
        let x: CGFloat
        let y: CGFloat
        let duration: Double
        let delay: Double
    }

    let stars: [Spec]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<stars.count, id: \.self) { index in
                    TwinkleStarDot(spec: stars[index])
                        .position(
                            x: geo.size.width * stars[index].x,
                            y: geo.size.height * stars[index].y
                        )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct TwinkleStarDot: View {
    let spec: StarField.Spec
    @State private var animate = false

    var body: some View {
        Image(systemName: "sparkle")
            .resizable()
            .scaledToFit()
            .frame(width: spec.size, height: spec.size)
            .foregroundStyle(spec.color)
            .opacity(animate ? 1 : 0.25)
            .scaleEffect(animate ? 1.15 : 0.7)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: spec.duration)
                        .repeatForever(autoreverses: true)
                        .delay(spec.delay)
                ) {
                    animate = true
                }
            }
    }
}

enum StarPresets {
    static let splash: [StarField.Spec] = [
        .init(size: 12, color: LumiColor.purple1, x: 0.12, y: 0.08, duration: 2.0, delay: 0),
        .init(size: 9, color: LumiColor.purpleLighter, x: 0.86, y: 0.18, duration: 2.4, delay: 0.5),
        .init(size: 14, color: LumiColor.purple2, x: 0.16, y: 0.86, duration: 1.8, delay: 1.0),
        .init(size: 8, color: LumiColor.textBody, x: 0.90, y: 0.74, duration: 2.1, delay: 1.4),
    ]

    static let welcome: [StarField.Spec] = [
        .init(size: 13, color: LumiColor.purple1, x: 0.10, y: 0.04, duration: 2.2, delay: 0),
        .init(size: 9, color: LumiColor.purpleLighter, x: 0.88, y: 0.12, duration: 1.9, delay: 0.6),
        .init(size: 11, color: LumiColor.purple2, x: 0.06, y: 0.46, duration: 2.4, delay: 1.1),
        .init(size: 8, color: LumiColor.textBody, x: 0.92, y: 0.52, duration: 2.0, delay: 0.3),
        .init(size: 10, color: LumiColor.purple1, x: 0.22, y: 0.24, duration: 2.1, delay: 0.9),
        .init(size: 7, color: LumiColor.textBody, x: 0.72, y: 0.06, duration: 1.7, delay: 1.3),
        .init(size: 9, color: LumiColor.purpleLighter, x: 0.80, y: 0.36, duration: 2.3, delay: 0.2),
        .init(size: 6, color: LumiColor.purple2, x: 0.16, y: 0.60, duration: 1.6, delay: 0.8),
    ]

    static let plan: [StarField.Spec] = [
        .init(size: 13, color: LumiColor.purple1, x: 0.10, y: 0.04, duration: 2.2, delay: 0),
        .init(size: 9, color: LumiColor.purpleLighter, x: 0.88, y: 0.12, duration: 1.9, delay: 0.6),
        .init(size: 11, color: LumiColor.purple2, x: 0.06, y: 0.46, duration: 2.4, delay: 1.1),
        .init(size: 8, color: LumiColor.textBody, x: 0.92, y: 0.52, duration: 2.0, delay: 0.3),
        .init(size: 10, color: LumiColor.purpleLighter, x: 0.14, y: 0.30, duration: 1.8, delay: 0.5),
    ]

    static let celebration: [StarField.Spec] = [
        .init(size: 9, color: LumiColor.purple1, x: 0.08, y: 0.03, duration: 2.2, delay: 0),
        .init(size: 7, color: LumiColor.purpleLighter, x: 0.90, y: 0.02, duration: 1.9, delay: 0.6),
        .init(size: 6, color: LumiColor.textBody, x: 0.04, y: 0.14, duration: 2.4, delay: 1.1),
        .init(size: 8, color: LumiColor.purple1, x: 0.95, y: 0.16, duration: 2.0, delay: 0.3),
    ]

    static let streak: [StarField.Spec] = [
        .init(size: 14, color: LumiColor.orange1, x: 0.14, y: 0.06, duration: 1.8, delay: 0),
        .init(size: 10, color: LumiColor.purple1, x: 0.86, y: 0.16, duration: 2.2, delay: 0.4),
        .init(size: 12, color: LumiColor.orange2, x: 0.08, y: 0.70, duration: 2.0, delay: 0.8),
        .init(size: 9, color: Color(hex: 0xFFE08A), x: 0.90, y: 0.76, duration: 1.6, delay: 1.2),
    ]
}
