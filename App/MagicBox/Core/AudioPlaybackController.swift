import AVFoundation
import Combine

/// Thin AVAudioPlayer wrapper shared by every actor's player view. Playback
/// is always driven by the content itself finishing (or the child tapping a
/// new tag) -- there is deliberately no scrub bar, no pause button, nothing
/// that turns this into "an interactive screen."
final class AudioPlaybackController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?
    private var onFinished: (() -> Void)?

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// Plays the clip at `url`. If `loop` is true the clip repeats forever
    /// (used for lullaby/music actors) and `onFinished` is never called --
    /// the caller is responsible for calling `stop()` when playback should
    /// end (e.g. the child taps a new tag).
    func play(url: URL, loop: Bool = false, onFinished: (() -> Void)? = nil) {
        stop()
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.numberOfLoops = loop ? -1 : 0
            player = newPlayer
            self.onFinished = loop ? nil : onFinished
            newPlayer.play()
            isPlaying = true
        } catch {
            isPlaying = false
            onFinished?()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        let completion = onFinished
        onFinished = nil
        completion?()
    }
}
