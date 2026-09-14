import CoreNFC
import Combine

/// Runs a (mostly) continuous NFC listening session while the child-facing
/// shell is active, so tapping a toy or card "just works" without any
/// button press. iOS still surfaces its own small system sheet while a
/// session is active and briefly on each detection -- that's an OS-level UI
/// CoreNFC does not let apps suppress, so it's treated as an accepted part
/// of the experience rather than something to fight.
///
/// Sessions time out after ~60s of inactivity (an Apple-imposed limit);
/// that and any other non-user-initiated invalidation restart quickly, as
/// long as `startContinuousListening()` is still the active mode. If a
/// session keeps dying much faster than that 60s figure, something is
/// genuinely wrong (not just "no tag nearby yet") -- restarts back off
/// exponentially in that case instead of hammering the NFC controller and
/// re-flashing the system sheet in a tight loop. See `recentInvalidations`
/// for on-device diagnosis (surfaced in `NFCTagInspectorView`).
final class NFCReaderService: NSObject, ObservableObject {
    static let shared = NFCReaderService()

    @Published private(set) var lastError: String?
    @Published private(set) var isSessionActive = false

    /// A rolling log of recent session invalidations (newest first, capped
    /// at 10), for diagnosing on-device without a Mac/Xcode attached --
    /// surfaced in `NFCTagInspectorView`. Each entry notes the error, how
    /// long the session lived before failing, and the restart delay chosen.
    @Published private(set) var recentInvalidations: [String] = []

    /// Fired on the main thread whenever a valid `TagReference` is read.
    /// Resolving that id to actual content is the caller's job (see
    /// `PlaybackCoordinator`) -- this service only knows about tags.
    var onTagReferenceDetected: ((TagReference) -> Void)?

    private var session: NFCNDEFReaderSession?
    private var shouldKeepListening = false
    private var sessionStartedAt: Date?
    private var consecutiveFastFailures = 0
    private let idleAlertMessage = "Hold your toy or card near the top of the phone."

    /// Restart delay after a normal invalidation (a completed read, a
    /// session timeout) -- kept short so the "always ready to tap" feel
    /// isn't lost.
    private let quickRestartDelay: TimeInterval = 0.4

    /// Restart delay after the system sheet's own "Cancel"/"Done" button is
    /// tapped. The sheet is modal and blocks all touches to the app
    /// underneath, including `ParentGateHotspot`'s 3-second hold -- with
    /// only `quickRestartDelay` before it reappeared, a parent had no
    /// usable window to reach it at all. A deliberate tap on the system
    /// button is a strong enough signal of intent (far more specific than a
    /// toddler tapping the tag-detection area) to justify a longer gap here.
    private let parentGateRestartDelay: TimeInterval = 8.0

    /// A session that dies faster than this (for a reason other than a
    /// user cancel) is treated as a failure loop, not a normal read/timeout
    /// cycle -- the genuine cases (a tag read, the ~60s OS timeout) both
    /// live far longer than this. Below it, `consecutiveFastFailures` grows
    /// and the restart delay backs off instead of hammering the NFC
    /// controller (and re-flashing the system sheet) many times a second.
    private let fastFailureThreshold: TimeInterval = 5.0
    private let maxBackoffDelay: TimeInterval = 10.0

    func startContinuousListening() {
        shouldKeepListening = true
        beginSession()
    }

    func stopListening() {
        shouldKeepListening = false
        session?.invalidate()
        session = nil
        isSessionActive = false
        consecutiveFastFailures = 0
    }

    private func beginSession() {
        guard NFCAvailability.isSupported else {
            lastError = "This device doesn't support NFC scanning."
            return
        }
        let newSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        newSession.alertMessage = idleAlertMessage
        newSession.begin()
        session = newSession
        sessionStartedAt = Date()
        isSessionActive = true
        lastError = nil
    }

    private func scheduleRestart(after delay: TimeInterval) {
        guard shouldKeepListening else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.shouldKeepListening else { return }
            self.beginSession()
        }
    }

    private func logInvalidation(error: Error, lifetime: TimeInterval, delay: TimeInterval) {
        let code = (error as? NFCReaderError)?.code.rawValue.description ?? "?"
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let entry = "\(formatter.string(from: Date())) — code \(code): \(error.localizedDescription) " +
            "(lived \(String(format: "%.1f", lifetime))s, restarting in \(String(format: "%.1f", delay))s)"
        recentInvalidations.insert(entry, at: 0)
        if recentInvalidations.count > 10 {
            recentInvalidations.removeLast()
        }
    }
}

extension NFCReaderService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for payload in message.records {
                if let reference = TagReference.from(ndefPayload: payload) {
                    DispatchQueue.main.async { [weak self] in
                        self?.onTagReferenceDetected?(reference)
                    }
                    return
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let lifetime = sessionStartedAt.map { Date().timeIntervalSince($0) } ?? 0
        let isUserCancel = (error as? NFCReaderError)?.code == .readerSessionInvalidationErrorUserCanceled

        let delay: TimeInterval
        if isUserCancel {
            // A deliberate tap on the system button -- see comment on
            // `parentGateRestartDelay`. Not a failure, so it doesn't affect
            // the backoff counter.
            delay = parentGateRestartDelay
        } else if lifetime < fastFailureThreshold {
            // Genuine reads and the ~60s OS timeout both live far longer
            // than this -- dying faster means something is actually wrong
            // (not "no tag nearby yet"). Back off exponentially so a
            // persistent failure can't hammer the NFC controller or
            // re-flash the system sheet multiple times a second.
            consecutiveFastFailures += 1
            delay = min(quickRestartDelay * pow(2, Double(consecutiveFastFailures)), maxBackoffDelay)
        } else {
            consecutiveFastFailures = 0
            delay = quickRestartDelay
        }

        DispatchQueue.main.async {
            self.isSessionActive = false
            self.logInvalidation(error: error, lifetime: lifetime, delay: delay)
        }
        // Always restart while in listening mode -- the box should never
        // just go quiet. It only truly stops listening when
        // `stopListening()` is called (the parent gate opening the
        // dashboard).
        scheduleRestart(after: delay)
    }
}
