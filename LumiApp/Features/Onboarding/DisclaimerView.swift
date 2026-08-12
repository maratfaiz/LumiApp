import SwiftUI

/// F2 — mandatory, cannot be dismissed by swipe/tap-outside/back gesture,
/// only by tapping the acknowledge button (Lumi_Acceptance_Criteria.docx).
struct DisclaimerView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        LumiFixedScreen {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LumiColor.danger.opacity(0.15))
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(LumiColor.danger.opacity(0.4), lineWidth: 2))
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(LumiColor.danger)
                }
                .padding(.top, 10)

                Text("Важно знать!")
                    .font(.lumi(19, weight: .black))
                    .foregroundStyle(Color.white)

                Text("Луми не заменяет профессиональную психологическую помощь и не ставит диагнозы.\n\nЕсли тебе очень тяжело, пожалуйста, обратись за поддержкой к близким или на горячую линию.")
                    .font(.lumi(13, weight: .semibold))
                    .foregroundStyle(LumiColor.textBody)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lumiCard()

                Spacer()

                PrimaryButton(title: "Я понимаю и согласен(на)", systemImage: "checkmark", action: onAcknowledge)
            }
        }
        // Intentionally no .interactiveDismissDisabled swipe/tap-outside handling
        // needed here since this is a plain switched-in view, not a sheet — if
        // it is later presented as a sheet, add .interactiveDismissDisabled(true).
    }
}

#Preview {
    DisclaimerView(onAcknowledge: {})
        .preferredColorScheme(.dark)
}
