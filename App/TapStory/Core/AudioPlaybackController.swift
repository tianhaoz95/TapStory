import AVFoundation
import Combine

/// Plays a `MediaRef` regardless of whether it's a bundled file, a parent's
/// recording, or text to be spoken live via on-device `AVSpeechSynthesizer`
/// -- shared by every actor's player view. Playback is always driven by the
/// content itself finishing (or the child tapping a new tag) -- there is
/// deliberately no scrub bar, no pause button, nothing that turns this into
/// "an interactive screen."
final class AudioPlaybackController: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false

    private var audioPlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var onFinished: (() -> Void)?
    /// Non-nil only while a looping speech clip should keep re-speaking
    /// itself (AVSpeechSynthesizer has no native "loop" option).
    private var loopingSpeechText: String?

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        speechSynthesizer.delegate = self
    }

    /// Resolves `mediaRef` and plays it with whichever engine applies. If
    /// `loop` is true, playback repeats forever (used for lullaby/music
    /// actors) and `onFinished` is never called -- the caller must call
    /// `stop()` when playback should end (e.g. the child taps a new tag).
    /// `onFailure` fires instead of `onFinished` if the reference can't be
    /// resolved or played at all (missing file, empty text, etc.).
    ///
    /// `fallbackSpeechText` lets a `.speech` ref be left blank when it would
    /// just repeat text the payload already stores elsewhere (a story
    /// page's `caption`, a vocab card's `word`, a song's `title`) -- that
    /// text is passed here and only actually read out if `mediaRef.ref` is
    /// empty, instead of every page paying for the same sentence twice in
    /// the tag's NDEF payload.
    func play(_ mediaRef: MediaRef, loop: Bool = false, fallbackSpeechText: String? = nil, onFinished: @escaping () -> Void, onFailure: @escaping () -> Void = {}) {
        stop()
        let effectiveRef = Self.resolvingBlankSpeechRef(mediaRef, fallback: fallbackSpeechText)
        guard let resolved = MediaResolver.resolve(effectiveRef) else {
            onFailure()
            return
        }
        switch resolved {
        case .file(let url):
            playFile(url: url, loop: loop, onFinished: onFinished, onFailure: onFailure)
        case .speech(let text):
            playSpeech(text: text, loop: loop, onFinished: onFinished)
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        loopingSpeechText = nil
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
    }

    private func playFile(url: URL, loop: Bool, onFinished: @escaping () -> Void, onFailure: @escaping () -> Void) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = loop ? -1 : 0
            audioPlayer = player
            self.onFinished = loop ? nil : onFinished
            player.play()
            isPlaying = true
        } catch {
            isPlaying = false
            onFailure()
        }
    }

    private func playSpeech(text: String, loop: Bool, onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        loopingSpeechText = loop ? text : nil
        isPlaying = true
        speechSynthesizer.speak(Self.makeUtterance(text))
    }

    /// Exposed at `internal` (rather than `private`) specifically so it can
    /// be unit tested directly -- it's pure logic with no side effects,
    /// unlike the rest of this class which drives real audio engines.
    static func resolvingBlankSpeechRef(_ mediaRef: MediaRef, fallback: String?) -> MediaRef {
        guard mediaRef.source == .speech,
              mediaRef.ref.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let fallback, !fallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return mediaRef
        }
        return MediaRef(source: .speech, ref: fallback)
    }

    private static func makeUtterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        // Slightly slower and a touch higher than the default reading rate
        // reads as warmer and easier for a toddler to follow.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.05
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        return utterance
    }
}

extension AudioPlaybackController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        let completion = onFinished
        onFinished = nil
        completion?()
    }
}

extension AudioPlaybackController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if let text = loopingSpeechText {
            synthesizer.speak(Self.makeUtterance(text))
            return
        }
        isPlaying = false
        let completion = onFinished
        onFinished = nil
        completion?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
    }
}
