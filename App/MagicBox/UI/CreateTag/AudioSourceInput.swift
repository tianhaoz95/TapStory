import SwiftUI

/// Lets a parent produce a `MediaRef` for one piece of narration/word audio
/// either by typing text -- synthesized on-device via `AVSpeechSynthesizer`
/// at playback time, no recording needed -- or by recording their own
/// voice. Typing text is the default: it's the easiest path for a parent
/// (copy/paste or type a sentence, no microphone permission, no re-recording
/// if you make a typo), while recording remains available for anyone who
/// wants the story told in their own voice.
struct AudioSourceInput: View {
    @Binding var mediaRef: MediaRef?
    var textPlaceholder: String = "Type what should be said..."

    private enum Mode: Hashable {
        case type
        case record
    }

    @State private var mode: Mode
    @State private var typedText: String
    @State private var recordingID: String?
    @StateObject private var previewPlayer = AudioPlaybackController()

    init(mediaRef: Binding<MediaRef?>, textPlaceholder: String = "Type what should be said...") {
        self._mediaRef = mediaRef
        self.textPlaceholder = textPlaceholder
        switch mediaRef.wrappedValue?.source {
        case .recording:
            _mode = State(initialValue: .record)
            _recordingID = State(initialValue: mediaRef.wrappedValue?.ref)
            _typedText = State(initialValue: "")
        default:
            _mode = State(initialValue: .type)
            _typedText = State(initialValue: mediaRef.wrappedValue?.ref ?? "")
            _recordingID = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Audio source", selection: $mode) {
                Text("Type Text").tag(Mode.type)
                Text("Record Voice").tag(Mode.record)
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _ in sync() }

            switch mode {
            case .type:
                TextField(textPlaceholder, text: $typedText, axis: .vertical)
                    .lineLimit(2...5)
                    .onChange(of: typedText) { _ in sync() }
                HStack {
                    Text("Spoken on-device -- no recording needed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            previewPlayer.play(MediaRef(source: .speech, ref: typedText), onFinished: {})
                        } label: {
                            Label("Preview", systemImage: "play.circle")
                        }
                        .font(.footnote)
                    }
                }
            case .record:
                AudioRecorderControl(recordingID: recordingID) { id in
                    recordingID = id
                    sync()
                }
            }
        }
        .onDisappear { previewPlayer.stop() }
    }

    private func sync() {
        switch mode {
        case .type:
            let trimmed = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
            mediaRef = trimmed.isEmpty ? nil : MediaRef(source: .speech, ref: typedText)
        case .record:
            mediaRef = recordingID.map { MediaRef(source: .recording, ref: $0) }
        }
    }
}
