import CoreNFC

enum NFCAvailability {
    static var isSupported: Bool {
        NFCNDEFReaderSession.readingAvailable
    }
}
