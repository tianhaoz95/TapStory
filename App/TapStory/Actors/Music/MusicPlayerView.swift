import SwiftUI

struct MusicPlayerView: View {
    let payload: MusicPayload
    let onFinished: () -> Void

    @StateObject private var audio = AudioPlaybackController()
    @State private var missingAudio = false
    @State private var pulse = false

    var body: some View {
        Group {
            if missingAudio {
                PlaybackErrorView(onFinished: onFinished)
            } else {
                VStack(spacing: 28) {
                    Spacer()
                    Image(systemName: payload.symbol)
                        .font(.system(size: 140))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .scaleEffect(pulse ? 1.08 : 0.96)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                    Text(payload.title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground).ignoresSafeArea())
                .onAppear { pulse = true }
            }
        }
        .onAppear { play() }
        .onDisappear { audio.stop() }
    }

    private func play() {
        audio.play(payload.audio, loop: payload.loop, fallbackSpeechText: payload.title, onFinished: onFinished, onFailure: { missingAudio = true })
    }
}
