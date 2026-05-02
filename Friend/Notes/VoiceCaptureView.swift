import SwiftUI

@MainActor
struct VoiceCaptureView: View {
    @Bindable var speech: SpeechRecognizer
    var onDone: () -> Void

    @State private var phase: Double = 0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)
            waveform
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(Color.healthRed)
                    Text("LISTENING…")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.88)
                        .foregroundStyle(Color.accent)
                }

                ScrollView {
                    Text(speech.transcript.isEmpty ? "Start talking…" : speech.transcript)
                        .font(.system(size: 17))
                        .foregroundStyle(speech.transcript.isEmpty ? Color.muted : Color.ink)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 22)

            Spacer()

            Button(action: onDone) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .bold))
                    Text("Done").font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.appBackground)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.ink))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 30)
        }
        .onReceive(timer) { _ in phase += 0.1 }
    }

    private var waveform: some View {
        let level = max(0.05, Double(speech.audioLevel))
        return HStack(alignment: .center, spacing: 4) {
            ForEach(0..<28, id: \.self) { i in
                let h = barHeight(for: i, level: level)
                Capsule()
                    .fill(Color.accent.opacity(0.6 + Double(i) * 0.012))
                    .frame(width: 4, height: h)
                    .animation(.easeInOut(duration: 0.08), value: h)
            }
        }
        .frame(height: 90)
    }

    private func barHeight(for i: Int, level: Double) -> CGFloat {
        // Two superimposed sine waves, scaled by audio level so the waveform
        // visibly grows when the user is loud and stays alive when quiet.
        let primary = abs(sin(phase + Double(i) * 0.45)) * 50
        let secondary = abs(sin(phase * 1.7 + Double(i) * 0.2)) * 18
        let base = 14.0
        return CGFloat(base + (primary + secondary) * (0.4 + level * 0.6))
    }
}
