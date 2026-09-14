import SwiftUI

/// What the child sees when nothing is playing: a deliberately low-
/// stimulation resting state -- solid black, a small static mark, no
/// motion, no bright colors. This screen should read as "off" at a glance,
/// not invite looking at or touching it. The whole point of the magic box
/// is that the interesting thing happens on the toy, not on the phone.
///
/// The continuous NFC listening session (see `NFCReaderService`) means
/// iOS's own "Ready to Scan" sheet is layered on top of this view for
/// almost the entire time it's visible -- CoreNFC ties that sheet's
/// lifetime 1:1 to the session, and a session has to be running
/// continuously for a tap to work with zero button presses, so there's no
/// API to keep listening without it. That sheet's chrome (title, icon,
/// color) can't be customized or restyled by any app, and it typically
/// covers close to the bottom half of the screen. So content here is
/// deliberately kept in the top portion, comfortably clear of that
/// coverage on any device, rather than vertically centered where it would
/// spend nearly all its time hidden behind the sheet.
struct IdleTapPromptView: View {
    private static let mark = Color(red: 0.88, green: 0.48, blue: 0.17).opacity(0.55) // muted accent orange

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "gift.fill")
                .font(.system(size: 34))
                .foregroundStyle(Self.mark)
            Text("TapStory")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Self.mark)
                .tracking(0.5)
            Spacer()
        }
        .padding(.top, 64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
    }
}
