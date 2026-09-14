import CoreNFC

/// Bridges `ContentRecord` to a single NDEF "media" record of type
/// `application/json`. Kept as an extension in the NFC layer (rather than in
/// Core) since `ContentRecord` itself has no CoreNFC dependency -- only tag
/// I/O does.
extension ContentRecord {
    private static let mediaType = "application/json"

    func makeNDEFPayload() throws -> NFCNDEFPayload {
        let data = try compactData
        guard let typeData = ContentRecord.mediaType.data(using: .utf8) else {
            throw NFCContentError.encodingFailed
        }
        return NFCNDEFPayload(
            format: .media,
            type: typeData,
            identifier: Data(),
            payload: data
        )
    }

    static func from(ndefPayload payload: NFCNDEFPayload) -> ContentRecord? {
        guard payload.typeNameFormat == .media,
              String(data: payload.type, encoding: .utf8) == mediaType else { return nil }
        return try? ContentRecord.decode(from: payload.payload)
    }
}

enum NFCContentError: Error {
    case encodingFailed
    case tagNotWritable
    case tagTooSmall(needed: Int, available: Int)
    case noTagDetected
}
