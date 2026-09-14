import CoreNFC
import Combine

/// Runs a (mostly) continuous NFC listening session while the child-facing
/// shell is active, so tapping a toy or card "just works" without any
/// button press. iOS still surfaces its own small system sheet while a
/// session is active and briefly on each detection -- that's an OS-level UI
/// CoreNFC does not let apps suppress, so it's treated as an accepted part
/// of the experience rather than something to fight.
///
/// Sessions time out after ~60s of inactivity (an Apple-imposed limit) and
/// are also invalidated after each detected read completes on some tag
/// types; both cases are treated the same way here: silently restart, as
/// long as `startContinuousListening()` is still the active mode.
final class NFCReaderService: NSObject, ObservableObject {
    static let shared = NFCReaderService()

    @Published private(set) var lastError: String?
    @Published private(set) var isSessionActive = false

    /// Fired on the main thread whenever a valid `TagReference` is read.
    /// Resolving that id to actual content is the caller's job (see
    /// `PlaybackCoordinator`) -- this service only knows about tags.
    var onTagReferenceDetected: ((TagReference) -> Void)?

    private var session: NFCNDEFReaderSession?
    private var shouldKeepListening = false
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

    func startContinuousListening() {
        shouldKeepListening = true
        beginSession()
    }

    func stopListening() {
        shouldKeepListening = false
        session?.invalidate()
        session = nil
        isSessionActive = false
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
        DispatchQueue.main.async {
            self.isSessionActive = false
        }
        // Always restart while in listening mode -- the box should never
        // just go quiet. That sheet is the one bit of native UI CoreNFC
        // won't let us hide, and it only truly stops listening when
        // `stopListening()` is called (the parent gate opening the
        // dashboard). But a user-initiated cancel gets a much longer delay
        // before restarting: the sheet is modal and blocks touches to
        // everything underneath, including the invisible parent-gate
        // hotspot, so restarting it quickly would leave no way in.
        let isUserCancel = (error as? NFCReaderError)?.code == .readerSessionInvalidationErrorUserCanceled
        scheduleRestart(after: isUserCancel ? parentGateRestartDelay : quickRestartDelay)
    }
}
