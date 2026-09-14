import CoreNFC

/// Writes a `TagReference` (just an id -- see `TagReference`) onto a blank
/// or reusable NFC sticker. This is the "turn any toy into a magic toy"
/// feature: a parent picks or records content in the app (which saves it
/// to `TagLibraryStore` under a stable id), then holds a cheap NTAG21x
/// sticker to the phone to pair the two.
final class NFCWriterService: NSObject, ObservableObject {
    static let shared = NFCWriterService()

    enum WriteResult {
        case success
        case failure(String)
    }

    @Published private(set) var isSessionActive = false

    private var activeSession: NFCNDEFReaderSession?
    private var referenceToWrite: TagReference?
    private var completion: ((WriteResult) -> Void)?

    func write(_ reference: TagReference, completion: @escaping (WriteResult) -> Void) {
        guard NFCAvailability.isSupported else {
            completion(.failure("This device doesn't support NFC."))
            return
        }
        referenceToWrite = reference
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
        guard let reference = referenceToWrite else {
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
                    self.performWrite(reference, to: tag, capacity: capacity, session: session)
                @unknown default:
                    self.finish(.failure("Unrecognized tag."), session: session)
                }
            }
        }
    }

    private func performWrite(_ reference: TagReference, to tag: NFCNDEFTag, capacity: Int, session: NFCNDEFReaderSession) {
        do {
            let ndefPayload = try reference.makeNDEFPayload()
            let message = NFCNDEFMessage(records: [ndefPayload])
            // In practice a TagReference is a couple dozen bytes -- this
            // check exists only as a safety net for truly exotic tags, not
            // because capacity is a real concern for what we write.
            guard message.length <= capacity else {
                self.finish(.failure("This tag is unusually small (\(capacity) bytes available, \(message.length) needed). Try a different sticker."), session: session)
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
            self.finish(.failure("Couldn't prepare this tag reference for writing."), session: session)
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
