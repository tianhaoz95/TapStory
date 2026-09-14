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

    /// Fired on the main thread whenever a valid `ContentRecord` is read.
    var onRecordDetected: ((ContentRecord) -> Void)?

    private var session: NFCNDEFReaderSession?
    private var shouldKeepListening = false
    private let idleAlertMessage = "Hold your toy or card near the top of the phone."

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

    private func scheduleRestartIfNeeded() {
        guard shouldKeepListening else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self, self.shouldKeepListening else { return }
            self.beginSession()
        }
    }
}

extension NFCReaderService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for payload in message.records {
                if let record = ContentRecord.from(ndefPayload: payload) {
                    DispatchQueue.main.async { [weak self] in
                        self?.onRecordDetected?(record)
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
        // Always restart while in listening mode -- including after a
        // "Cancel"/"Done" tap on the system sheet. That sheet is the one bit
        // of native UI CoreNFC won't let us hide, and a curious toddler will
        // eventually tap it; the box should never just go quiet because of
        // that. It only truly stops when `stopListening()` is called (the
        // parent gate opening the dashboard).
        scheduleRestartIfNeeded()
    }
}
