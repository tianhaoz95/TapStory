import SwiftUI

/// Fully automatic page-by-page story playback: no buttons, no scrub bar,
/// no "next" tap required. Each page's narration plays once; when it
/// finishes, the next page fades in automatically. After the last page, the
/// view calls `onFinished` so the shell can return to idle listening.
struct StoryPlayerView: View {
    let payload: StoryPayload
    let onFinished: () -> Void

    @StateObject private var audio = AudioPlaybackController()
    @State private var pageIndex = 0
    @State private var missingAudio = false

    var body: some View {
        Group {
            if missingAudio {
                PlaybackErrorView(onFinished: onFinished)
            } else {
                VStack(spacing: 32) {
                    Text(payload.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)

                    Spacer()

                    Image(systemName: currentPage.symbol)
                        .font(.system(size: 160))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .transition(.scale.combined(with: .opacity))
                        .id("symbol-\(pageIndex)")

                    Text(currentPage.caption)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                        .id("caption-\(pageIndex)")

                    Spacer()

                    PageDotsView(count: payload.pages.count, currentIndex: pageIndex)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .animation(.easeInOut(duration: 0.4), value: pageIndex)
            }
        }
        .onAppear { playCurrentPage() }
        .onDisappear { audio.stop() }
    }

    private var currentPage: StoryPage { payload.pages[pageIndex] }

    private func playCurrentPage() {
        guard let url = MediaResolver.url(for: currentPage.audio) else {
            missingAudio = true
            return
        }
        audio.play(url: url) {
            advance()
        }
    }

    private func advance() {
        if pageIndex + 1 < payload.pages.count {
            pageIndex += 1
            playCurrentPage()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onFinished()
            }
        }
    }
}

private struct PageDotsView: View {
    let count: Int
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }
}
