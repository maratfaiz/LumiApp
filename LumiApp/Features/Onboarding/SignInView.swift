import AuthenticationServices
import SwiftUI

/// F23 — Sign in with Apple. Spec detail beyond the feature-list entry
/// doesn't exist yet; this is a functional stub (real credential handling
/// still needs wiring to a backend, which per Lumi_Project_Handover.docx
/// hasn't been designed — Stage 5, Архитектура, is still open).
struct SignInView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Сохраним твой прогресс")
                .font(.lumiHeadline)
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { _ in
                onContinue()
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 32)
            Spacer()
        }
    }
}

#Preview {
    SignInView(onContinue: {})
}
