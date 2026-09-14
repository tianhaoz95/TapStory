import SwiftUI

/// What the child sees when nothing is playing: a calm, wordless-enough
/// invitation to tap a toy, and nothing else tappable. This is the resting
/// state of the "magic box" illusion.
struct IdleTapPromptView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse ? 1.08 : 0.94)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 96))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.tint)
            }
            Text("Tap a toy or card to begin!")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear { pulse = true }
    }
}
