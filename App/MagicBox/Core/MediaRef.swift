import Foundation

/// A reference to a piece of media (audio, mainly) that keeps the physical
/// tag tiny no matter how the content was authored:
/// - `.bundled` points at an asset shipped inside the app, addressed by name.
/// - `.recording` points at a file a parent recorded on-device, addressed by
///   a stable id. The actual bytes never touch the tag -- only this short
///   reference does -- so a multi-page story with real narration still fits
///   comfortably in a few hundred bytes of NDEF payload.
struct MediaRef: Codable, Equatable {
    enum Source: String, Codable {
        case bundled
        case recording
    }

    var source: Source
    var ref: String
}

/// Resolves a `MediaRef` to a playable file URL, regardless of whether the
/// underlying audio shipped with the app or was recorded by a parent.
enum MediaResolver {
    static func url(for mediaRef: MediaRef) -> URL? {
        switch mediaRef.source {
        case .bundled:
            // Bundled resources land flat at the bundle's top level (see
            // the comment on `BundledLibrary`), not under a subdirectory,
            // regardless of how they're organized on disk.
            return Bundle.main.url(forResource: mediaRef.ref, withExtension: "m4a")
        case .recording:
            return RecordingStore.shared.fileURL(forRecordingID: mediaRef.ref)
        }
    }
}
