import SwiftUI

@main
struct TapStoryApp: App {
    init() {
        // Runs regardless of which screen is showing, so it belongs here
        // rather than in any particular view's lifecycle.
        PhoneWatchConnectivityService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
