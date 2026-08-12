import XCTest
@testable import MyDailySoundtrack

@MainActor
final class PlaybackStoreTests: XCTestCase {
    func testPlaybackStoreStartsAndPausesWithStubRenderer() async {
        let store = PlaybackStore(renderer: StubAudioRenderer())

        store.start()
        try? await Task.sleep(for: .milliseconds(350))
        XCTAssertEqual(store.state, .playing)

        store.pause()
        try? await Task.sleep(for: .milliseconds(120))
        XCTAssertEqual(store.state, .paused)
    }

    func testPlaybackStoreSurfacesRendererFailure() async {
        let renderer = StubAudioRenderer()
        renderer.shouldFailNextStart = true
        let store = PlaybackStore(renderer: renderer)

        store.start()
        try? await Task.sleep(for: .milliseconds(350))

        XCTAssertEqual(store.state, .error("オーディオの初期化に失敗しました"))
    }
}
