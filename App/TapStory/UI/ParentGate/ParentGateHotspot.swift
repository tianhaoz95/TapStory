import SwiftUI

/// An otherwise-invisible corner hotspot that opens the parent gate after a
/// deliberate 3-second hold. Placed over the bottom-trailing corner of the
/// locked shell so it survives on top of whatever content is playing.
struct ParentGateHotspot: View {
    @Binding var isChallengePresented: Bool
    @State private var isHolding = false

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.001)) // effectively invisible, still hit-testable
            .frame(width: 64, height: 64)
            .overlay(alignment: .bottomTrailing) {
                if isHolding {
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 3)
                        .frame(width: 40, height: 40)
                        .padding(12)
                }
            }
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 3, maximumDistance: 30) {
                isHolding = false
                isChallengePresented = true
            } onPressingChanged: { pressing in
                isHolding = pressing
            }
            .accessibilityHidden(true)
    }
}
