import SwiftUI

/// F34 — служебные состояния, exact copy from Lumi_Functional_Requirements.docx.
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
        VStack(spacing: 16) {
            MascotView(state: .neutral).frame(width: 80, height: 80)
            Text(message)
                .font(.lumiBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(LumiColor.accent)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Загрузка…").font(.lumiCaption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorStateView: View {
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.secondary)
            Text("Что-то пошло не так — проверьте соединение")
                .font(.lumiBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Повторить", action: retry)
                .buttonStyle(.borderedProminent)
                .tint(LumiColor.accent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Empty") {
    EmptyStateView(
        message: "Пока пусто — здесь появятся ваши достижения, как только вы пройдёте первый урок",
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
