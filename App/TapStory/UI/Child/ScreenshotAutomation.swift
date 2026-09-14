#if DEBUG
import SwiftUI

/// Drives the app into a specific screen state on launch, purely from an
/// environment variable -- no UI taps, no XCUITest -- so App Store
/// screenshots can be scripted with `xcrun simctl launch` alone. See
/// `Scripts/capture_screenshots.sh`.
///
/// Set `TAPSTORY_SCREENSHOT_SCENE` (via `SIMCTL_CHILD_TAPSTORY_SCREENSHOT_SCENE`
/// when using `simctl launch`) to one of:
/// - `"idle"` -- a recognized no-op: leaves the resting idle screen as-is,
///   but (like every other value) marks screenshot mode active via
///   `isActive`, which hides debug-only chrome.
/// - `"dashboard"` -- opens the parent dashboard directly, skipping the gate.
/// - `"<type>:<bundled-file-stem>"` -- e.g. `"story:magic_monkey"`,
///   `"vocab_card:letter_m"`, `"music:lullaby_01"` -- simulates tapping
///   that bundled item, via the same debug hook `DebugSimulateTapButton` uses.
///
/// Since `AppSettings.isScreenDisplayEnabled` defaults to off, a content
/// scene also force-enables it on the simulator taking the screenshot
/// (never on a real user's device) so the capture actually shows the
/// optional visual mode rather than the (identical-looking) idle screen.
///
/// Compiled out of Release builds entirely, same as the rest of this
/// screenshot/debug tooling.
enum ScreenshotAutomation {
    /// True whenever a screenshot scene is being driven -- used to hide
    /// debug-only chrome (like `DebugSimulateTapButton`'s ladybug icon)
    /// that shouldn't appear in an App Store or marketing screenshot.
    static var isActive: Bool {
        !(ProcessInfo.processInfo.environment["TAPSTORY_SCREENSHOT_SCENE"] ?? "").isEmpty
    }

    static func applyIfNeeded(isDashboardPresented: Binding<Bool>) {
        guard let scene = ProcessInfo.processInfo.environment["TAPSTORY_SCREENSHOT_SCENE"],
              !scene.isEmpty else { return }

        // A short delay lets the view hierarchy and NFC listening session
        // settle first, so this doesn't race the shell's own .onAppear work.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if scene == "dashboard" {
                isDashboardPresented.wrappedValue = true
                return
            }

            let parts = scene.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return }
            let type = parts[0]
            let fileStem = parts[1]

            let items = BundledLibrary.items(forType: type)
            guard let item = items.first(where: { $0.fileName == "\(fileStem).json" }) else { return }
            // Screen Display defaults to off (see AppSettings), so without
            // this a content screenshot would show nothing but the idle
            // screen. Marketing screenshots are meant to show what the
            // optional visual mode looks like, so force it on here --
            // this only ever runs in a screenshot-automation launch, never
            // in a real build a user would see.
            AppSettings.shared.isScreenDisplayEnabled = true
            PlaybackCoordinator.shared.debugSimulateTap(item.record)
        }
    }
}
#endif
