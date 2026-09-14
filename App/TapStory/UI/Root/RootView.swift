import SwiftUI

struct RootView: View {
    var body: some View {
        ChildLockedShellView()
            .tint(.orange)
            // Locked to light appearance so illustrations/colors stay
            // predictable for a toddler regardless of system dark mode.
            .preferredColorScheme(.light)
    }
}
