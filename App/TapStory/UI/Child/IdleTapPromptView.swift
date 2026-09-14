import SwiftUI

/// What the child sees when nothing is playing: a deliberately low-
/// stimulation resting state -- solid black, a static grey icon, and a
/// small caption. No motion and no bright colors on purpose: this screen
/// should read as "off" at a glance, not invite looking at or touching it.
/// The whole point of the magic box is that the interesting thing happens
/// on the toy, not on the phone.
struct IdleTapPromptView: View {
    private static let grey = Color(white: 0.45)

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 56))
                .foregroundStyle(Self.grey)
            Text("Tap a toy or card to begin")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Self.grey)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}
