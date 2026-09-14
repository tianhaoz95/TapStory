import Combine
import WatchConnectivity

/// The iPhone side of the Watch remote control. Bridges `AppSettings`,
/// `PlaybackCoordinator`, and `TagLibraryStore` to the paired Watch over
/// `WatchConnectivity` -- a local link between paired devices, no
/// internet or account involved, same as everything else in this app.
///
/// This exists specifically so a parent can toggle Screen Display, stop
/// playback, or start a saved story from their wrist *without touching
/// the phone a toddler is holding* -- doing any of that by reaching for
/// the phone itself would add exactly the screen time this app exists to
/// avoid.
final class PhoneWatchConnectivityService: NSObject, ObservableObject {
    static let shared = PhoneWatchConnectivityService()

    private var cancellables: Set<AnyCancellable> = []
    private var didStart = false

    private override init() {
        super.init()
    }

    /// Activates the session and starts pushing status on every relevant
    /// change. Called once from `TapStoryApp` at launch -- this needs to
    /// run regardless of which screen is showing, so it doesn't belong to
    /// any particular view's lifecycle.
    func start() {
        guard !didStart, WCSession.isSupported() else { return }
        didStart = true

        WCSession.default.delegate = self
        WCSession.default.activate()

        Publishers.CombineLatest3(
            AppSettings.shared.$isScreenDisplayEnabled,
            PlaybackCoordinator.shared.$currentRecord,
            TagLibraryStore.shared.$entries
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.pushStatus()
        }
        .store(in: &cancellables)
    }

    private func currentStatus() -> PhoneStatus {
        PhoneStatus(
            isScreenDisplayEnabled: AppSettings.shared.isScreenDisplayEnabled,
            nowPlayingTitle: PlaybackCoordinator.shared.nowPlayingTitle,
            library: TagLibraryStore.shared.entries.map { entry in
                let icon = ActorRegistry.shared.actor(for: entry.type).map { type(of: $0).iconSystemName } ?? "questionmark"
                return PhoneStatus.LibrarySummary(id: entry.id, title: entry.title, iconSystemName: icon)
            }
        )
    }

    private func pushStatus() {
        guard WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(currentStatus()) else { return }
        do {
            try WCSession.default.updateApplicationContext(["status": data])
        } catch {
            // The Watch app isn't installed, or the context couldn't be
            // queued -- nothing actionable to do; the next real change
            // will try again.
        }
    }

    private func handle(_ command: WatchCommand) {
        switch command {
        case .setScreenDisplayEnabled(let isEnabled):
            AppSettings.shared.isScreenDisplayEnabled = isEnabled
        case .stopPlayback:
            PlaybackCoordinator.shared.finishCurrent()
        case .playLibraryEntry(let id):
            PlaybackCoordinator.shared.remotePlay(entryID: id)
        }
    }
}

extension PhoneWatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.pushStatus()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Required for multi-watch support: reactivate for whichever
        // watch is now paired.
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        if let command = try? JSONDecoder().decode(WatchCommand.self, from: messageData) {
            DispatchQueue.main.async { [weak self] in
                self?.handle(command)
                replyHandler((try? JSONEncoder().encode(self?.currentStatus())) ?? Data())
            }
        } else {
            replyHandler(Data())
        }
    }

    /// Fallback path for when the Watch sent a command while the phone
    /// wasn't immediately reachable (`transferUserInfo` queues for later
    /// delivery rather than failing outright).
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["command"] as? Data,
              let command = try? JSONDecoder().decode(WatchCommand.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.handle(command)
        }
    }
}
