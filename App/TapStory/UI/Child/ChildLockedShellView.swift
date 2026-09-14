import SwiftUI

/// The screen a toddler actually sees: full-bleed, no visible chrome, no
/// buttons besides the invisible parent-gate hotspot. This view owns
/// starting/stopping the continuous NFC listening session and swaps between
/// the idle prompt and whichever actor is currently playing.
struct ChildLockedShellView: View {
    @ObservedObject private var coordinator = PlaybackCoordinator.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var isParentChallengePresented = false
    @State private var isDashboardPresented = false

    var body: some View {
        ZStack {
            if settings.isScreenDisplayEnabled {
                if let record = coordinator.currentRecord,
                   let actor = ActorRegistry.shared.actor(for: record.type) {
                    actor.makeChildView(for: record) {
                        coordinator.finishCurrent()
                    }
                    .id(record) // ensures a fresh instance if the same content plays twice
                } else if coordinator.lastUnresolvedTagID != nil || coordinator.lastUnrecognizedType != nil {
                    // Either an orphaned tag (its library entry was deleted, or
                    // it was written by a different phone) or a recognized-but-
                    // corrupted record. Same calm, brief error either way.
                    PlaybackErrorView(onFinished: { coordinator.clearError() })
                } else {
                    IdleTapPromptView()
                }
            } else {
                // Default mode: the screen never changes, ever -- "as if it
                // were not a screen device." The actor view is still
                // mounted (invisibly) so its playback/auto-advance timing
                // logic runs exactly as it would if shown; only visibility
                // differs. Audio is identical in both modes.
                IdleTapPromptView()
                if let record = coordinator.currentRecord,
                   let actor = ActorRegistry.shared.actor(for: record.type) {
                    actor.makeChildView(for: record) {
                        coordinator.finishCurrent()
                    }
                    .id(record)
                    .opacity(0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }

            VStack {
                HStack {
                    #if DEBUG
                    if !ScreenshotAutomation.isActive {
                        DebugSimulateTapButton()
                    }
                    #endif
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    ParentGateHotspot(isChallengePresented: $isParentChallengePresented)
                        .padding(20)
                }
            }
        }
        // Deliberately NOT .ignoresSafeArea() here: each child view bleeds
        // its own background to the edges individually (see e.g.
        // StoryPlayerView), but keeps its actual content -- text, icons --
        // within the safe area. A blanket ignoresSafeArea() at this level
        // previously let top-anchored content (a story's title) render
        // straight under the Dynamic Island/notch on real devices.
        .statusBarHidden(true)
        .onAppear {
            coordinator.startListening()
            #if DEBUG
            ScreenshotAutomation.applyIfNeeded(isDashboardPresented: $isDashboardPresented)
            #endif
        }
        .sheet(isPresented: $isParentChallengePresented) {
            ParentGateChallengeView(
                onUnlocked: {
                    isParentChallengePresented = false
                    isDashboardPresented = true
                },
                onCancel: { isParentChallengePresented = false }
            )
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $isDashboardPresented) {
            ParentDashboardView()
        }
        .onChange(of: isDashboardPresented) { presented in
            // The dashboard's own NFC read/write tools need exclusive use of
            // CoreNFC, so pause the child's continuous listening session
            // while it's open and resume the moment it closes.
            if presented {
                coordinator.stopListening()
            } else {
                coordinator.startListening()
            }
        }
        .onChange(of: coordinator.lastUnrecognizedType) { _ in clearErrorImmediatelyIfHidden() }
        .onChange(of: coordinator.lastUnresolvedTagID) { _ in clearErrorImmediatelyIfHidden() }
    }

    /// In audio-only mode, error states are never shown at all -- not even
    /// briefly -- so there's nothing to auto-dismiss via `PlaybackErrorView`.
    /// Clear it right away instead of letting it linger unseen, which would
    /// otherwise surface unexpectedly if the parent later turns screen
    /// display on.
    private func clearErrorImmediatelyIfHidden() {
        guard !settings.isScreenDisplayEnabled else { return }
        if coordinator.lastUnrecognizedType != nil || coordinator.lastUnresolvedTagID != nil {
            coordinator.clearError()
        }
    }
}

extension ContentRecord: Identifiable {
    var id: String {
        // Stable enough for SwiftUI's `.id()` invalidation purposes: two
        // reads of the same tag produce the same identity, a different tag
        // (or re-authored content) produces a different one.
        "\(type)-\((try? compactData.hashValue) ?? 0)"
    }
}
