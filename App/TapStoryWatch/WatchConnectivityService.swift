import Combine
import WatchConnectivity

/// The Watch side of the remote control: sends `WatchCommand`s to the
/// paired iPhone and keeps `status` in sync with whatever `PhoneStatus`
/// the phone last pushed.
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var status: PhoneStatus = .empty
    @Published private(set) var isReachable = false

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends a command to the phone. Applies it optimistically to local
    /// `status` first so the watch UI feels instant (a toggle flips the
    /// moment you tap it) -- the next real push from the phone corrects
    /// this if it ever disagrees. Falls back to queued delivery
    /// (`transferUserInfo`) when the phone isn't immediately reachable,
    /// rather than silently dropping the command.
    func send(_ command: WatchCommand) {
        applyOptimistically(command)
        guard let data = try? JSONEncoder().encode(command) else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
            queueForLater(data)
            return
        }

        if session.isReachable {
            session.sendMessageData(data, replyHandler: { [weak self] replyData in
                guard let status = try? JSONDecoder().decode(PhoneStatus.self, from: replyData) else { return }
                DispatchQueue.main.async { self?.status = status }
            }, errorHandler: { [weak self] _ in
                self?.queueForLater(data)
            })
        } else {
            queueForLater(data)
        }
    }

    private func queueForLater(_ data: Data) {
        WCSession.default.transferUserInfo(["command": data])
    }

    private func applyOptimistically(_ command: WatchCommand) {
        switch command {
        case .setScreenDisplayEnabled(let isEnabled):
            status.isScreenDisplayEnabled = isEnabled
        case .stopPlayback:
            status.nowPlayingTitle = nil
        case .playLibraryEntry(let id):
            status.nowPlayingTitle = status.library.first(where: { $0.id == id })?.title
        }
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }

    #if os(iOS)
    // WCSessionDelegate requires these two on iOS (multi-watch support)
    // but marks them *unavailable* on watchOS -- and TapStoryWatch's
    // sources genuinely get compiled under both SDKs: once for real
    // watchOS, and once under the iOS SDK as part of the TapStory
    // scheme's "Embed Watch Content" step when built via plain
    // `xcodebuild` from the command line. Neither omitting nor always
    // including these compiles cleanly on both -- hence the #if.
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["status"] as? Data,
              let status = try? JSONDecoder().decode(PhoneStatus.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.status = status
        }
    }
}
