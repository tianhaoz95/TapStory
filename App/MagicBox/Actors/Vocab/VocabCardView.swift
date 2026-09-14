import SwiftUI

/// Plays the word's pronunciation twice (a simple, well-established pattern
/// for vocabulary reinforcement) then returns to idle listening. No touch
/// interaction required -- tapping the card again on the phone just
/// re-triggers the same experience via a fresh NFC read.
struct VocabCardView: View {
    let payload: VocabPayload
    let onFinished: () -> Void

    @StateObject private var audio = AudioPlaybackController()
    @State private var repeatsRemaining = 2
    @State private var missingAudio = false

    var body: some View {
        Group {
            if missingAudio {
                PlaybackErrorView(onFinished: onFinished)
            } else {
                VStack(spacing: 28) {
                    Spacer()

                    if let letter = payload.letter {
                        Text(letter.uppercased())
                            .font(.system(size: 120, weight: .heavy, design: .rounded))
                            .foregroundStyle(.tint)
                    }

                    Image(systemName: payload.symbol)
                        .font(.system(size: 130))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)

                    Text(payload.word)
                        .font(.system(size: 44, weight: .bold, design: .rounded))

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
        .onAppear { playOnce() }
        .onDisappear { audio.stop() }
    }

    private func playOnce() {
        guard let url = MediaResolver.url(for: payload.audio) else {
            missingAudio = true
            return
        }
        audio.play(url: url) {
            repeatsRemaining -= 1
            if repeatsRemaining > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    playOnce()
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onFinished()
                }
            }
        }
    }
}
