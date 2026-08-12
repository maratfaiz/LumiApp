import SwiftUI

// MARK: - Buttons

/// Big gradient CTA pill, the design's
/// `linear-gradient(135deg,#8b6cf6,#6c4fe0)` primary button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.lumi(15, weight: .heavy))
            .foregroundStyle(isEnabled ? Color.white : LumiColor.textDim)
            .lumiPrimaryButtonSurface(isEnabled: isEnabled)
        }
        .buttonStyle(.lumiPlain)
        .disabled(!isEnabled)
    }
}

/// Плоская кнопка Lumi: как `.plain`, но нажатие ловит **вся** область
/// метки, а не только непрозрачный текст внутри неё.
///
/// В SwiftUI `Button { Text("Начать").frame(maxWidth: .infinity) }` кликается
/// лишь по буквам: расширенная рамка и отступы прозрачны для hit-testing, а
/// фон, навешенный снаружи кнопки, в её область попадания не входит вовсе.
/// Именно поэтому по широкой фиолетовой кнопке «Начать урок» можно было
/// промахнуться, попав в неё же. `contentShape` в стиле чинит это разом для
/// всех кнопок приложения; заодно появляется отклик на нажатие, которого
/// у `.plain` нет.
struct LumiPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == LumiPlainButtonStyle {
    static var lumiPlain: LumiPlainButtonStyle { LumiPlainButtonStyle() }
}

extension View {
    /// Фиолетовая «таблетка» основной кнопки.
    ///
    /// Заливка и `contentShape` живут **внутри** метки кнопки намеренно.
    /// Раньше фон вешался снаружи (`Button { Text() }.background(...)`), и
    /// нажатие ловил только сам текст: широкая кнопка выглядела как кнопка,
    /// но реагировала лишь на попадание по буквам. Отсюда и «не могу начать
    /// урок» — по градиенту рядом со словами ничего не происходило.
    func lumiPrimaryButtonSurface(isEnabled: Bool = true, radius: CGFloat = 14) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                shape.fill(isEnabled ? AnyShapeStyle(LumiGradient.primary) : AnyShapeStyle(Color.white.opacity(0.08)))
            )
            .contentShape(shape)
            .shadow(color: isEnabled ? LumiColor.purple2.opacity(0.45) : .clear, radius: 14, y: 8)
    }
}

/// Secondary bordered pill, used where a screen offers a second, quieter action.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.lumi(14, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(LumiColor.textBright)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LumiColor.cardFillLight))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(LumiColor.cardBorder, lineWidth: 1))
        .buttonStyle(.lumiPlain)
    }
}

/// Plain text link button, e.g. "Вернуться на главную".
struct TextLinkButton: View {
    let title: String
    var color: Color = LumiColor.textSecondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.lumi(12.5, weight: .bold))
                .foregroundStyle(color)
                .padding(12)
        }
        .buttonStyle(.lumiPlain)
    }
}

/// Small pill-style toggle used on the breathing / affirmation / meditation
/// control rows (repeat, sound, speed, info…).
struct ControlPillButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                LumiGlyph(name: icon, size: 14)
                Text(label).font(.lumi(10, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
        }
        .foregroundStyle(isActive ? LumiColor.purpleLight : LumiColor.textTertiary)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? LumiColor.purple1.opacity(0.16) : LumiColor.cardFillLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? LumiColor.purple1.opacity(0.4) : LumiColor.cardBorder, lineWidth: 1)
        )
        .buttonStyle(.lumiPlain)
    }
}

/// Circular transport control (play/pause, prev/next).
struct TransportButton: View {
    let systemImage: String
    var size: CGFloat = 52
    var prominent: Bool = false
    var accessibilityTitle: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(prominent ? Color.white : LumiColor.textBody)
                .frame(width: size, height: size)
        }
        .background(
            Circle().fill(prominent ? AnyShapeStyle(LumiGradient.primary) : AnyShapeStyle(LumiColor.cardFill))
        )
        .overlay(Circle().stroke(Color.white.opacity(prominent ? 0 : 0.12), lineWidth: 1))
        .shadow(color: prominent ? LumiColor.purple1.opacity(0.4) : .clear, radius: 10, y: 4)
        .buttonStyle(.lumiPlain)
        .accessibilityLabel(accessibilityTitle)
    }
}

// MARK: - Cards

private struct CardBackground: ViewModifier {
    var fill: Color
    var border: Color
    var borderWidth: CGFloat
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(border, lineWidth: borderWidth))
    }
}

extension View {
    /// Translucent panel look shared by most cards in the design
    /// (`background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1)`).
    func lumiCard(
        fill: Color = LumiColor.cardFill,
        border: Color = LumiColor.cardBorder,
        borderWidth: CGFloat = 1,
        radius: CGFloat = 16
    ) -> some View {
        modifier(CardBackground(fill: fill, border: border, borderWidth: borderWidth, radius: radius))
    }

    /// Tinted variant used for "highlighted"/selected panels.
    func lumiAccentCard(_ color: Color = LumiColor.purple1, radius: CGFloat = 16) -> some View {
        modifier(CardBackground(fill: color.opacity(0.14), border: color.opacity(0.3), borderWidth: 1, radius: radius))
    }
}

/// Section label — the design's tiny uppercase caption above a group.
struct SectionLabel: View {
    let text: String
    var color: Color = LumiColor.textTertiary
    var size: CGFloat = 11

    var body: some View {
        Text(text.uppercased())
            .font(.lumi(size, weight: .bold))
            .foregroundStyle(color)
    }
}

/// Colored count chip used in the Home header and screen toolbars
/// (streak / lumens / freezes).
struct StatChip: View {
    let icon: String
    let text: String
    let color: Color
    var fallbackSystemImage: String = "circle"

    var body: some View {
        HStack(spacing: 3) {
            LumiIcon(name: icon, size: 11, fallbackSystemImage: fallbackSystemImage)
            Text(text).font(.lumi(11, weight: .heavy))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.15)))
    }
}

/// Tappable icon + label row used by the onboarding questionnaire.
struct SelectableOptionRow: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                LumiGlyph(name: icon, size: 18)
                    .foregroundStyle(isSelected ? LumiColor.purpleLight : LumiColor.textBody)
                    .frame(width: 22)
                Text(title)
                    .font(.lumi(13, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Color.white : LumiColor.textBody)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if isSelected {
                    ZStack {
                        Circle().fill(LumiColor.purple1).frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? LumiColor.purple1.opacity(0.18) : LumiColor.cardFillLight)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? LumiColor.purple1 : LumiColor.cardBorder, lineWidth: isSelected ? 2 : 1)
        )
        .buttonStyle(.lumiPlain)
    }
}

// MARK: - Progress

/// Thin fill bar (splash loading, lesson progress, course progress).
struct LumiProgressBar: View {
    /// 0...1
    var progress: Double
    var height: CGFloat = 6
    var fill: AnyShapeStyle = AnyShapeStyle(LumiGradient.primary)
    var track: Color = Color.white.opacity(0.1)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2).fill(track)
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(fill)
                    .frame(width: max(0, geo.size.width * CGFloat(min(max(progress, 0), 1))))
            }
        }
        .frame(height: height)
    }
}

/// Segmented step indicator at the top of each onboarding screen.
struct StepProgressBar: View {
    let total: Int
    /// 1-based
    let current: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(1...max(total, 1), id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= current ? AnyShapeStyle(LumiGradient.primary) : AnyShapeStyle(Color.white.opacity(0.12)))
                    .frame(height: 4)
            }
        }
    }
}

struct OnboardingHeader: View {
    let step: Int
    let total: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(step) / \(total)")
                .font(.lumi(11, weight: .bold))
                .foregroundStyle(LumiColor.textSecondary)
            StepProgressBar(total: total, current: step)
        }
    }
}

/// 1...5 rating selector used on the first onboarding question.
struct RatingCircle: View {
    let number: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(number)")
                .font(.lumi(15, weight: .heavy))
                .foregroundStyle(isSelected ? Color.white : LumiColor.textBody)
                .frame(width: 44, height: 44)
        }
        .background(
            Circle().fill(isSelected ? AnyShapeStyle(LumiGradient.primary) : AnyShapeStyle(LumiColor.cardFill))
        )
        .overlay(Circle().stroke(Color.white.opacity(isSelected ? 0 : 0.12), lineWidth: 1))
        .shadow(color: isSelected ? LumiColor.purple2.opacity(0.5) : .clear, radius: 10, y: 4)
        .buttonStyle(.lumiPlain)
    }
}

/// Circular progress ring with a soft glow behind it — breathing timer,
/// meditation timer, plan builder, streak counter.
struct LumiProgressRing<Center: View>: View {
    var progress: Double
    var diameter: CGFloat = 196
    var lineWidth: CGFloat = 12
    var tint: AnyShapeStyle = AnyShapeStyle(LumiColor.purple1)
    var glow: Color = LumiColor.purple1
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glow.opacity(0.32), .clear],
                        center: .center, startRadius: 0, endRadius: diameter * 0.6
                    )
                )
                .frame(width: diameter * 1.18, height: diameter * 1.18)
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
            center
        }
        .frame(width: diameter * 1.18, height: diameter * 1.18)
    }
}
