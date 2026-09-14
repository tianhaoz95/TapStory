import Foundation

/// A reference to a piece of audio that keeps the physical tag tiny no
/// matter how the content was authored:
/// - `.bundled` points at an asset shipped inside the app, addressed by name.
/// - `.recording` points at a file a parent recorded on-device, addressed by
///   a stable id -- the actual bytes never touch the tag, only this short id.
/// - `.speech` holds the literal text to be spoken on-device via
///   `AVSpeechSynthesizer` at playback time. This is the easiest authoring
///   path for a parent: type a sentence instead of recording audio. Nothing
///   is pre-rendered or stored as a file -- synthesis happens live, from
///   this text, every time the tag is tapped.
struct MediaRef: Codable, Equatable {
    enum Source: String, Codable {
        case bundled
        case recording
        case speech
    }

    var source: Source
    var ref: String
}

/// What a `MediaRef` resolves to: either a file to hand to `AVAudioPlayer`,
/// or text to hand to `AVSpeechSynthesizer`. `AudioPlaybackController`
/// picks the right playback engine based on which case comes back.
enum ResolvedAudio {
    case file(URL)
    case speech(text: String)
}

enum MediaResolver {
    static func resolve(_ mediaRef: MediaRef) -> ResolvedAudio? {
        switch mediaRef.source {
        case .bundled:
            guard let url = Bundle.main.url(forResource: mediaRef.ref, withExtension: "m4a") else { return nil }
            return .file(url)
        case .recording:
            let url = RecordingStore.shared.fileURL(forRecordingID: mediaRef.ref)
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return .file(url)
        case .speech:
            let text = mediaRef.ref.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return .speech(text: text)
        }
    }
}
