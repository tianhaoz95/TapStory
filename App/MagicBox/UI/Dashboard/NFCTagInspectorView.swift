import SwiftUI

/// A parent-facing debugging tool: scan any tag and see exactly what Magic
/// Box would do with it, without handing the phone to a toddler first.
struct NFCTagInspectorView: View {
    @StateObject private var reader = NFCReaderService()
    @State private var lastRecord: ContentRecord?
    @State private var statusText = "Not scanning."

    var body: some View {
        VStack(spacing: 20) {
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let record = lastRecord {
                VStack(alignment: .leading, spacing: 8) {
                    Label(record.type, systemImage: "tag.fill")
                        .font(.headline)
                    if let actor = ActorRegistry.shared.actor(for: record.type), actor.canHandle(record) {
                        Label("Recognized - will play correctly", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Unrecognized or malformed payload", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    ScrollView {
                        Text(prettyJSON(for: record))
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 260)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button {
                startScan()
            } label: {
                Label("Scan a Tag", systemImage: "wave.3.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Test / Inspect a Tag")
        .onDisappear { reader.stopListening() }
    }

    private func startScan() {
        statusText = "Hold a tag near the top of the phone..."
        reader.onRecordDetected = { record in
            lastRecord = record
            statusText = "Read successfully."
            reader.stopListening()
        }
        reader.startContinuousListening()
    }

    private func prettyJSON(for record: ContentRecord) -> String {
        guard let data = try? JSONEncoder.pretty.encode(record),
              let string = String(data: data, encoding: .utf8) else {
            return "(unable to render)"
        }
        return string
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
