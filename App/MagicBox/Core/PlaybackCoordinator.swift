import Foundation
import UIKit

/// Bridges NFC reads to whatever the child-facing shell is currently
/// showing. Tapping a new tag while something is already playing simply
/// swaps the content immediately -- the same "put down one figure, pick up
/// another" behavior as dedicated story-box hardware.
final class PlaybackCoordinator: ObservableObject {
    static let shared = PlaybackCoordinator()

    @Published private(set) var currentRecord: ContentRecord?
    @Published private(set) var lastUnrecognizedType: String?

    private init() {
        NFCReaderService.shared.onRecordDetected = { [weak self] record in
            self?.handle(record)
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

    #if DEBUG
    /// Feeds a record through exactly the same path a real NFC read would,
    /// for testing in the iOS Simulator -- which has no NFC hardware and
    /// Apple provides no way to simulate a scan for. Compiled out of
    /// Release builds entirely; see `DebugSimulateTapButton`.
    func debugSimulateTap(_ record: ContentRecord) {
        handle(record)
    }
    #endif

    private func handle(_ record: ContentRecord) {
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
