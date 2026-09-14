import XCTest
@testable import MagicBox

/// Hosted inside the app process (see the note in BundledLibraryTests), so
/// `Bundle.main` lookups here are against the real app bundle.
final class MediaResolverTests: XCTestCase {
    func testBundledResolvesToAFile() {
        // lullaby_01.m4a is the one bundled audio file that ships with the app.
        guard case .file(let url)? = MediaResolver.resolve(MediaRef(source: .bundled, ref: "lullaby_01")) else {
            return XCTFail("expected lullaby_01 to resolve to a bundled file")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testUnknownBundledNameResolvesToNil() {
        XCTAssertNil(MediaResolver.resolve(MediaRef(source: .bundled, ref: "does_not_exist")))
    }

    func testNonexistentRecordingResolvesToNil() {
        XCTAssertNil(MediaResolver.resolve(MediaRef(source: .recording, ref: UUID().uuidString)))
    }

    func testSpeechResolvesToTextVerbatim() {
        guard case .speech(let text)? = MediaResolver.resolve(MediaRef(source: .speech, ref: "M! M is for Monkey.")) else {
            return XCTFail("expected a .speech(text:) case")
        }
        XCTAssertEqual(text, "M! M is for Monkey.")
    }

    func testBlankSpeechTextResolvesToNil() {
        XCTAssertNil(MediaResolver.resolve(MediaRef(source: .speech, ref: "   \n")))
    }

    func testBlankSpeechRefFallsBackToProvidedText() {
        let resolved = AudioPlaybackController.resolvingBlankSpeechRef(
            MediaRef(source: .speech, ref: ""),
            fallback: "Once upon a time..."
        )
        XCTAssertEqual(resolved, MediaRef(source: .speech, ref: "Once upon a time..."))
    }

    func testWhitespaceOnlySpeechRefAlsoFallsBack() {
        let resolved = AudioPlaybackController.resolvingBlankSpeechRef(
            MediaRef(source: .speech, ref: "   "),
            fallback: "The Magic Monkey"
        )
        XCTAssertEqual(resolved, MediaRef(source: .speech, ref: "The Magic Monkey"))
    }

    func testExplicitSpeechRefIsNotOverriddenByFallback() {
        let explicit = MediaRef(source: .speech, ref: "M! M is for Monkey.")
        let resolved = AudioPlaybackController.resolvingBlankSpeechRef(explicit, fallback: "Monkey")
        XCTAssertEqual(resolved, explicit)
    }

    func testBlankSpeechRefWithNoFallbackStaysBlank() {
        let blank = MediaRef(source: .speech, ref: "")
        XCTAssertEqual(AudioPlaybackController.resolvingBlankSpeechRef(blank, fallback: nil), blank)
        XCTAssertEqual(AudioPlaybackController.resolvingBlankSpeechRef(blank, fallback: "  "), blank)
    }

    func testFallbackIsIgnoredForNonSpeechSources() {
        let recordingRef = MediaRef(source: .recording, ref: "some-uuid")
        XCTAssertEqual(AudioPlaybackController.resolvingBlankSpeechRef(recordingRef, fallback: "ignored"), recordingRef)
    }
}
