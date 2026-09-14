import SwiftUI

/// The screen a toddler actually sees: full-bleed, no visible chrome, no
/// buttons besides the invisible parent-gate hotspot. This view owns
/// starting/stopping the continuous NFC listening session and swaps between
/// the idle prompt and whichever actor is currently playing.
struct ChildLockedShellView: View {
    @ObservedObject private var coordinator = PlaybackCoordinator.shared
    @State private var isParentChallengePresented = false
    @State private var isDashboardPresented = false

    var body: some View {
        ZStack {
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
        .ignoresSafeArea()
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
