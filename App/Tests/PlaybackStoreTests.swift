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

    func testPlaybackStorePassesScorePlanToRenderer() async {
        let renderer = RecordingAudioRenderer()
        let initialPlan = ScorePlan(
            padLevel: 0.8,
            arpLevel: 0.2,
            beatLevel: 0.6,
            fxLevel: 0.1,
            fieldNoiseLevel: 0.3,
            baseBPM: 118,
            tempoFollowRate: 0.5,
            filter: 0.7,
            reverb: 0.4
        )
        let store = PlaybackStore(renderer: renderer, initialPlan: initialPlan)

        store.start()
        try? await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(renderer.startPlan, initialPlan)

        let runningPlan = ScorePlan(
            padLevel: 0.4,
            arpLevel: 0.8,
            beatLevel: 0.9,
            fxLevel: 0.2,
            fieldNoiseLevel: 0.2,
            baseBPM: 132,
            tempoFollowRate: 0.7,
            filter: 0.9,
            reverb: 0.2
        )
        store.setPlan(runningPlan)
        try? await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(renderer.lastUpdatePlan, runningPlan)
    }
}

@MainActor
private final class RecordingAudioRenderer: AudioRendering {
    private(set) var startPlan: ScorePlan?
    private(set) var lastUpdatePlan: ScorePlan?

    func start(tag: GeoTag, plan: ScorePlan) async throws {
        startPlan = plan
    }

    func pause() async {}

    func stop() async {}

    func update(tag: GeoTag, plan: ScorePlan) async {
        lastUpdatePlan = plan
    }
}
