import SwiftUI
import AVFoundation

/// Records one short audio clip into `RecordingStore`, with a record/stop
/// button and a play-back-to-check button. Used anywhere the parent
/// authoring flow needs "say the word / read the page" input.
struct AudioRecorderControl: View {
    /// Existing recording id to start from (e.g. re-editing a draft), or nil
    /// for a brand new clip.
    @State var recordingID: String?
    /// Called whenever a new recording is finalized.
    var onRecorded: (String) -> Void

    @StateObject private var recorder = AudioRecorderController()
    @StateObject private var playback = AudioPlaybackController()
    @State private var permissionDenied = false

    var body: some View {
        HStack(spacing: 16) {
            Button {
                toggleRecording()
            } label: {
                Label(recorder.isRecording ? "Stop" : (recordingID == nil ? "Record" : "Re-record"),
                      systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .red : .accentColor)

            if let recordingID, !recorder.isRecording {
                Button {
                    playback.play(MediaRef(source: .recording, ref: recordingID), onFinished: {})
                } label: {
                    Label("Play", systemImage: "play.circle")
                }
                .buttonStyle(.bordered)
            }

            if recorder.isRecording {
                Text(recorder.elapsedTimeString)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else if recordingID != nil {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
            }
        }
        .alert("Microphone access needed", isPresented: $permissionDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Turn on microphone access for Magic Box in Settings to record custom stories and words.")
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            if let id = recorder.stop() {
                recordingID = id
                onRecorded(id)
            }
            return
        }
        recorder.requestPermissionAndStart { granted in
            if !granted { permissionDenied = true }
        }
    }
}

/// Thin AVAudioRecorder wrapper. Recordings are saved directly into
/// `RecordingStore` under a fresh UUID.
final class AudioRecorderController: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedTimeString = "0:00"

    private var recorder: AVAudioRecorder?
    private var currentID: String?
    private var timer: Timer?
    private var startDate: Date?

    func requestPermissionAndStart(deniedHandler: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.start()
                } else {
                    deniedHandler(false)
                }
            }
        }
    }

    private func start() {
        let (id, url) = RecordingStore.shared.newRecordingURL()
        currentID = id
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.record()
            recorder = newRecorder
            isRecording = true
            startDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                self?.tick()
            }
        } catch {
            isRecording = false
        }
    }

    private func tick() {
        guard let startDate else { return }
        let elapsed = Int(Date().timeIntervalSince(startDate))
        elapsedTimeString = String(format: "%d:%02d", elapsed / 60, elapsed % 60)
    }

    @discardableResult
    func stop() -> String? {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        isRecording = false
        return currentID
    }
}
