import Foundation

/// The entire wire protocol between the iPhone app and its Watch
/// companion. This file is compiled into *both* the `TapStory` and
/// `TapStoryWatch` targets (see `project.yml`) rather than hand-copied,
/// so the two sides can never drift out of sync with each other.
///
/// Transport is plain `WatchConnectivity` (`WCSession`) -- a local
/// peer-to-peer link between paired devices over Bluetooth/local WiFi,
/// no internet and no account involved, consistent with the rest of this
/// app's no-network design. See `PhoneWatchConnectivityService` (iOS) and
/// `WatchConnectivityService` (watchOS).

/// Sent Watch -> iPhone. Every command that lets a parent act on the
/// phone without touching it while a toddler is holding it.
enum WatchCommand: Codable, Equatable {
    /// Mirrors `AppSettings.isScreenDisplayEnabled`.
    case setScreenDisplayEnabled(Bool)
    /// Mirrors `PlaybackCoordinator.finishCurrent()`.
    case stopPlayback
    /// Mirrors `PlaybackCoordinator.remotePlay(entryID:)` -- plays a
    /// `TagLibraryEntry` by id exactly as if its tag had been tapped,
    /// without needing the physical tag at all.
    case playLibraryEntry(id: String)
}

/// Pushed iPhone -> Watch (via `updateApplicationContext`, so the Watch
/// always has the latest snapshot even if it wasn't reachable when it was
/// sent) whenever anything relevant changes, so the Watch UI never has to
/// poll.
struct PhoneStatus: Codable, Equatable {
    var isScreenDisplayEnabled: Bool
    var nowPlayingTitle: String?
    var library: [LibrarySummary]

    struct LibrarySummary: Codable, Equatable, Identifiable {
        var id: String
        var title: String
        var iconSystemName: String
    }

    static let empty = PhoneStatus(isScreenDisplayEnabled: false, nowPlayingTitle: nil, library: [])
}
