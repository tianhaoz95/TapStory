import SwiftUI

/// A parent-facing debugging tool: scan any tag and see exactly what Magic
/// Box would do with it, without handing the phone to a toddler first.
/// Since a tag only ever stores a `TagReference` id, this also resolves it
/// against `TagLibraryStore` -- an orphaned tag (deleted library entry, or
/// written by a different phone) shows up clearly here rather than as a
/// silent no-op.
struct NFCTagInspectorView: View {
    @StateObject private var reader = NFCReaderService()
    @State private var lastReference: TagReference?
    @State private var statusText = "Not scanning."

    var body: some View {
        VStack(spacing: 20) {
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let reference = lastReference {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tag id: \(reference.id)", systemImage: "tag.fill")
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let entry = TagLibraryStore.shared.entry(withID: reference.id) {
                        Label("Resolves to \"\(entry.title)\"", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        if let actor = ActorRegistry.shared.actor(for: entry.record.type), actor.canHandle(entry.record) {
                            Label("Content is valid -- will play correctly", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Content is malformed and won't play", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                        ScrollView {
                            Text(prettyJSON(for: entry.record))
                                .font(.system(.footnote, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 220)
                    } else {
                        Label("Not in this phone's \"My Tags\" library", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("This tag is orphaned on this device -- its library entry was deleted, or it was written by a different phone. Write new content to it from \"My Tags\" or \"Create a New Magic Tag.\"")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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
        reader.onTagReferenceDetected = { reference in
            lastReference = reference
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
