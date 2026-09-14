import Foundation
import UIKit

/// Bridges NFC reads to whatever the child-facing shell is currently
/// showing. A tap only ever gives us a `TagReference` (an id); this is
/// what resolves that id to real content via `TagLibraryStore` and hands
/// the result to the right `ContentActor`. Tapping a new tag while
/// something is already playing simply swaps the content immediately --
/// the same "put down one figure, pick up another" behavior as dedicated
/// story-box hardware.
final class PlaybackCoordinator: ObservableObject {
    static let shared = PlaybackCoordinator()

    @Published private(set) var currentRecord: ContentRecord?
    @Published private(set) var lastUnrecognizedType: String?
    /// Set when a tag's id doesn't match anything in this phone's "My
    /// Tags" library -- e.g. its library entry was deleted, or the tag was
    /// written by a different phone/install.
    @Published private(set) var lastUnresolvedTagID: String?

    private init() {
        NFCReaderService.shared.onTagReferenceDetected = { [weak self] reference in
            self?.handle(reference)
        }
    }

    func startListening() {
        UIApplication.shared.isIdleTimerDisabled = true
        NFCReaderService.shared.startContinuousListening()
    }

    func stopListening() {
        UIApplication.shared.isIdleTimerDisabled = false
        NFCReaderService.shared.stopListening()
        currentRecord = nil
    }

    func finishCurrent() {
        currentRecord = nil
    }

    /// Title of whatever's currently playing, using the same `"title"`
    /// payload-field convention `BundledLibrary` relies on for its picker
    /// UI. Used to show a "Now Playing" readout on the Watch app.
    var nowPlayingTitle: String? {
        currentRecord?.payload["title"]?.stringValue
    }

    /// Plays a saved library entry by id, exactly as if its physical tag
    /// had been tapped -- this is what lets the Watch app's "play a saved
    /// story" remote control work without any physical tag involved.
    func remotePlay(entryID: String) {
        guard let entry = TagLibraryStore.shared.entry(withID: entryID) else { return }
        present(entry.record)
    }

    /// Dismisses whichever error state is currently showing (called by
    /// `PlaybackErrorView` after its brief auto-dismiss timer).
    func clearError() {
        lastUnrecognizedType = nil
        lastUnresolvedTagID = nil
    }

    #if DEBUG
    /// Feeds a record straight to the actor-dispatch step, skipping the
    /// tag-id resolution a real read would go through, for testing in the
    /// iOS Simulator -- which has no NFC hardware and Apple provides no
    /// way to simulate a scan for. Compiled out of Release builds
    /// entirely; see `DebugSimulateTapButton`.
    func debugSimulateTap(_ record: ContentRecord) {
        present(record)
    }
    #endif

    private func handle(_ reference: TagReference) {
        guard let entry = TagLibraryStore.shared.entry(withID: reference.id) else {
            lastUnresolvedTagID = reference.id
            lastUnrecognizedType = nil
            currentRecord = nil
            return
        }
        lastUnresolvedTagID = nil
        present(entry.record)
    }

    private func present(_ record: ContentRecord) {
        lastUnresolvedTagID = nil
        guard let actor = ActorRegistry.shared.actor(for: record.type), actor.canHandle(record) else {
            lastUnrecognizedType = record.type
            currentRecord = nil
            return
        }
        lastUnrecognizedType = nil
        // Force a fresh view even if the same tag is tapped twice in a row
        // by clearing first; SwiftUI otherwise sees "no change" and won't
        // restart playback from the top.
        currentRecord = nil
        DispatchQueue.main.async {
            self.currentRecord = record
        }
    }
}
