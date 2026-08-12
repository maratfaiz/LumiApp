import SwiftUI

/// F34 — служебные состояния, restyled to the design's dark treatment
/// (dashed empty slot, gradient CTA, muted skeleton rows).
struct EmptyStateView: View {
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .foregroundStyle(Color.white.opacity(0.15))
                .background(RoundedRectangle(cornerRadius: 20).fill(LumiColor.cardFillFaint))
                .frame(width: 80, height: 80)
            Text("Пока пусто")
                .font(.lumi(15, weight: .heavy))
                .foregroundStyle(Color.white)
            Text(message)
                .font(.lumi(12, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.lumi(13, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 13)
                }
                .buttonStyle(.lumiPlain)
                .background(RoundedRectangle(cornerRadius: 14).fill(LumiGradient.primary))
            }
            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LumiBackground())
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(LumiColor.purple1)
                .scaleEffect(1.4)
            Text("Загрузка…")
                .font(.lumi(13, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
            VStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 12).fill(LumiColor.cardFillLight).frame(height: 60)
                RoundedRectangle(cornerRadius: 4).fill(LumiColor.cardFillLight).frame(height: 16).frame(maxWidth: 240)
                RoundedRectangle(cornerRadius: 4).fill(LumiColor.cardFillLight).frame(height: 16).frame(maxWidth: 170)
            }
            .padding(.top, 10)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LumiBackground())
    }
}

struct ErrorStateView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color(hex: 0xFF8A65).opacity(0.15)).frame(width: 60, height: 60)
                Text("!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFF8A65))
            }
            Text("Что-то пошло не так")
                .font(.lumi(15, weight: .heavy))
                .foregroundStyle(Color.white)
            Text("Проверьте соединение и повторите попытку")
                .font(.lumi(12, weight: .semibold))
                .foregroundStyle(LumiColor.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: retry) {
                Text("Повторить")
                    .font(.lumi(13, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.lumiPlain)
            .background(RoundedRectangle(cornerRadius: 14).fill(LumiGradient.primary))
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LumiBackground())
    }
}

#Preview("Empty") {
    EmptyStateView(
        message: "Здесь появятся ваши достижения, как только вы пройдёте первый урок",
        actionTitle: "К урокам",
        action: {}
    )
}

#Preview("Loading") {
    LoadingStateView()
}

#Preview("Error") {
    ErrorStateView(retry: {})
}
