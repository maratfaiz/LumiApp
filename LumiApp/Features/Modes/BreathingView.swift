import SwiftUI

/// F26 — 4-7-8 breathing technique (single unified technique, replacing
/// 3 earlier-described variants per Lumi_Functional_Requirements.docx v2.0).
/// TODO(task: Build Breathing mode screen): full player (timer, phase
/// indicator, play/pause, repeat, speed, technique info) — this is a
/// placeholder stub so Home can link to it now.
struct BreathingView: View {
    var body: some View {
        VStack(spacing: 16) {
            MascotView(state: .neutral).frame(width: 100, height: 100)
            Text("Дыхание 4-7-8").font(.lumiHeadline)
            Text("Скоро здесь появится плеер дыхательной техники.")
                .font(.lumiBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .navigationTitle("Дыхание")
    }
}

#Preview {
    NavigationStack { BreathingView() }
}
