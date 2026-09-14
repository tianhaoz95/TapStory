import SwiftUI

/// Everything the child-facing playback shell needs from a content "actor" --
/// the thing that knows how to turn one `type` of `ContentRecord` into a
/// full-screen experience (a story, a vocab card, a song, or whatever gets
/// added later).
///
/// New activity types are added by writing a new conformance and registering
/// it in `ActorRegistry.registerBuiltInActors()` -- nothing else in the app
/// needs to change, including the NFC read/write code and the tag schema.
protocol ContentActor {
    /// The `type` string this actor claims from `ContentRecord.type`.
    static var typeIdentifier: String { get }

    /// A short, parent-facing label used in "Choose a type" pickers when
    /// authoring a new tag (e.g. "Story", "Vocabulary Card").
    static var displayName: String { get }

    /// SF Symbol shown alongside `displayName` in authoring UI.
    static var iconSystemName: String { get }

    /// Validates that `record.payload` is shaped the way this actor expects,
    /// without fully decoding it. Used to fail fast with a friendly error if
    /// a tag is corrupted or was written by an incompatible app version.
    func canHandle(_ record: ContentRecord) -> Bool

    /// Builds the full-screen child-facing view for this record.
    @ViewBuilder
    func makeChildView(for record: ContentRecord, onFinished: @escaping () -> Void) -> AnyView
}

extension ContentActor {
    func canHandle(_ record: ContentRecord) -> Bool {
        record.type == Self.typeIdentifier && record.payload.objectValue != nil
    }
}
