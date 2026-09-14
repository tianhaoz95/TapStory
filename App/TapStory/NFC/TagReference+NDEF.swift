import CoreNFC

/// Bridges `TagReference` to a single NDEF "media" record of type
/// `application/json`. Kept as an extension in the NFC layer (rather than
/// in Core) since `TagReference` itself has no CoreNFC dependency -- only
/// tag I/O does.
extension TagReference {
    private static let mediaType = "application/json"

    func makeNDEFPayload() throws -> NFCNDEFPayload {
        let data = try compactData
        guard let typeData = TagReference.mediaType.data(using: .utf8) else {
            throw NFCContentError.encodingFailed
        }
        return NFCNDEFPayload(
            format: .media,
            type: typeData,
            identifier: Data(),
            payload: data
        )
    }

    static func from(ndefPayload payload: NFCNDEFPayload) -> TagReference? {
        guard payload.typeNameFormat == .media,
              String(data: payload.type, encoding: .utf8) == mediaType else { return nil }
        return try? TagReference.decode(from: payload.payload)
    }
}

enum NFCContentError: Error {
    case encodingFailed
    case tagNotWritable
    case tagTooSmall(needed: Int, available: Int)
    case noTagDetected
}
