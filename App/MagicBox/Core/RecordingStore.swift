import Foundation

/// Stores parent-recorded audio clips on-device (Documents/Recordings), each
/// addressed by a UUID string. This is the "custom toy" half of content
/// authoring: a parent records their own voice, the recording gets an id,
/// and only that id -- never the audio itself -- is what gets written to an
/// NFC tag or embedded in a `ContentRecord`.
final class RecordingStore {
    static let shared = RecordingStore()

    private let directory: URL

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// A fresh destination URL to record into. The caller is responsible for
    /// actually writing audio there (see `AudioRecorderController`).
    func newRecordingURL() -> (id: String, url: URL) {
        let id = UUID().uuidString
        return (id, fileURL(forRecordingID: id))
    }

    func fileURL(forRecordingID id: String) -> URL {
        directory.appendingPathComponent("\(id).m4a")
    }

    func exists(recordingID id: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(forRecordingID: id).path)
    }

    func delete(recordingID id: String) {
        try? FileManager.default.removeItem(at: fileURL(forRecordingID: id))
    }
}
