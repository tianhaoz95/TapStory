import Foundation

/// Small persisted app-wide preferences. Just one setting today, so plain
/// `UserDefaults` is the right amount of machinery -- no need for the
/// JSON-file stores used for richer data like `TagLibraryStore`.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let isScreenDisplayEnabled = "isScreenDisplayEnabled"
    }

    /// Whether tapping a tag shows anything on screen at all. **Off by
    /// default** -- `UserDefaults.bool(forKey:)` returns `false` for a
    /// key that's never been set, which is exactly the default this
    /// feature wants, for both fresh installs and upgrades from a version
    /// that predates this setting.
    ///
    /// When `false`, the screen stays on the idle resting state
    /// regardless of what's playing -- "as if it were not a screen
    /// device" was the explicit design goal. Audio (speech, recordings,
    /// bundled clips) plays exactly the same either way; only whether the
    /// content actor's view is visible changes. See `ChildLockedShellView`.
    @Published var isScreenDisplayEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isScreenDisplayEnabled, forKey: Keys.isScreenDisplayEnabled)
        }
    }

    private init() {
        isScreenDisplayEnabled = UserDefaults.standard.bool(forKey: Keys.isScreenDisplayEnabled)
    }
}
