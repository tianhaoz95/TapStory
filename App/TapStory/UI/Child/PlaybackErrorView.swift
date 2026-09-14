import SwiftUI

/// Shown when a tag decodes but its payload is malformed, or a referenced
/// audio/recording file is missing. Kept calm and wordless-enough for a
/// toddler to not be alarmed; it auto-dismisses back to the idle listening
/// screen after a moment.
struct PlaybackErrorView: View {
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.orange)
            Text("Hmm, that magic didn't work.")
                .font(.title2.bold())
            Text("Try tapping again!")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onFinished()
            }
        }
    }
}
