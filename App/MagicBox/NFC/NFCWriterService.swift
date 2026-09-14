import CoreNFC

/// Writes a `ContentRecord` onto a blank (or reusable) NFC sticker. This is
/// the "turn any toy into a magic toy" feature: a parent picks or records
/// content in the app, then holds a cheap NTAG21x sticker to the phone to
/// pair the two.
final class NFCWriterService: NSObject, ObservableObject {
    static let shared = NFCWriterService()

    enum WriteResult {
        case success
        case failure(String)
    }

    @Published private(set) var isSessionActive = false

    private var activeSession: NFCNDEFReaderSession?
    private var recordToWrite: ContentRecord?
    private var completion: ((WriteResult) -> Void)?

    func write(_ record: ContentRecord, completion: @escaping (WriteResult) -> Void) {
        guard NFCAvailability.isSupported else {
            completion(.failure("This device doesn't support NFC."))
            return
        }
        recordToWrite = record
        self.completion = completion
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session.alertMessage = "Hold a blank tag near the top of the phone."
        session.begin()
        activeSession = session
        isSessionActive = true
    }

    func cancel() {
        activeSession?.invalidate()
    }

    private func finish(_ result: WriteResult, session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                session.alertMessage = "Tag ready! \u{2728}"
            case .failure(let message):
                session.alertMessage = message
            }
            session.invalidate()
            self.completion?(result)
            self.completion = nil
            self.isSessionActive = false
        }
    }
}

extension NFCWriterService: NFCNDEFReaderSessionDelegate {
    // Required by the protocol; writing goes through `didDetect tags:`
    // instead so we get direct tag connect/write access.
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {}

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let record = recordToWrite else {
            session.invalidate(errorMessage: "Nothing to write.")
            return
        }
        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = "Only one tag at a time, please."
            session.restartPolling()
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }
            if let error {
                self.finish(.failure(error.localizedDescription), session: session)
                return
            }
            tag.queryNDEFStatus { status, capacity, error in
                if let error {
                    self.finish(.failure(error.localizedDescription), session: session)
                    return
                }
                switch status {
                case .notSupported:
                    self.finish(.failure("This tag can't store data and can't be used with Magic Box."), session: session)
                case .readOnly:
                    self.finish(.failure("This tag is locked and can't be reprogrammed."), session: session)
                case .readWrite:
                    self.performWrite(record, to: tag, capacity: capacity, session: session)
                @unknown default:
                    self.finish(.failure("Unrecognized tag."), session: session)
                }
            }
        }
    }

    private func performWrite(_ record: ContentRecord, to tag: NFCNDEFTag, capacity: Int, session: NFCNDEFReaderSession) {
        do {
            let ndefPayload = try record.makeNDEFPayload()
            let message = NFCNDEFMessage(records: [ndefPayload])
            guard message.length <= capacity else {
                self.finish(.failure("This content is too big for this tag (\(message.length) of \(capacity) bytes). Try a larger sticker (NTAG215/216) or a shorter recording."), session: session)
                return
            }
            tag.writeNDEF(message) { [weak self] error in
                guard let self else { return }
                if let error {
                    self.finish(.failure(error.localizedDescription), session: session)
                } else {
                    self.finish(.success, session: session)
                }
            }
        } catch {
            self.finish(.failure("Couldn't prepare this content for writing."), session: session)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isSessionActive = false
        }
        guard let completion else { return }
        if let readerError = error as? NFCReaderError, readerError.code == .readerSessionInvalidationErrorUserCanceled {
            completion(.failure("Cancelled."))
        } else {
            completion(.failure(error.localizedDescription))
        }
        self.completion = nil
    }
}
