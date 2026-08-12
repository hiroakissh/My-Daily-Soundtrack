import XCTest
@testable import MyDailySoundtrack

final class SceneScoreTests: XCTestCase {
    func testSceneClassifierRequiresDoubleHitThenLocks() {
        let classifier = SceneClassifier(lockDuration: 60)
        let baseDate = Date()
        let snapshot = ContextSnapshot(
            geoTag: .urban,
            timeBand: .morning,
            weather: .clear,
            motion: .walking,
            cadence: 100,
            timestamp: baseDate
        )

        let first = classifier.classify(snapshot: snapshot, now: baseDate)
        XCTAssertNil(first.current)
        XCTAssertEqual(first.candidate, .morningIntro)

        let second = classifier.classify(snapshot: snapshot, now: baseDate.addingTimeInterval(1))
        XCTAssertEqual(second.current, .morningIntro)
        XCTAssertNotNil(second.lockRemaining)

        // Within lock window, should stay locked even if candidate changes.
        let different = ContextSnapshot(
            geoTag: .cafe,
            timeBand: .daytime,
            weather: .rainy,
            motion: .walking,
            cadence: 90,
            timestamp: baseDate.addingTimeInterval(10)
        )
        let third = classifier.classify(snapshot: different, now: baseDate.addingTimeInterval(10))
        XCTAssertEqual(third.current, .morningIntro)
        XCTAssertEqual(third.candidate, .rainyWalk)
    }

    func testScorePlannerAdjustsForMotion() {
        let preset = SceneScorePreset(
            scene: .sunnyWalk,
            plan: ScorePlan(
                padLevel: 0.5,
                arpLevel: 0.3,
                beatLevel: 0.4,
                fxLevel: 0.2,
                fieldNoiseLevel: 0.2,
                baseBPM: 100,
                tempoFollowRate: 0.5,
                filter: 0.5,
                reverb: 0.5
            )
        )
        let planner = ScorePlanner(presets: [preset])

        let walking = planner.plan(scene: .sunnyWalk, motion: .walking, cadence: 120)
        XCTAssertGreaterThan(walking.beatLevel, 0.4)
        XCTAssertGreaterThan(walking.baseBPM, 100)

        let idle = planner.plan(scene: .sunnyWalk, motion: .idle, cadence: nil)
        XCTAssertLessThan(idle.beatLevel, 0.4)
        XCTAssertLessThan(idle.baseBPM, 100)
    }
}
