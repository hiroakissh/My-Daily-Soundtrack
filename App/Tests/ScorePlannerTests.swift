import XCTest
@testable import MyDailySoundtrack

final class ScorePlannerTests: XCTestCase {
    func testCadenceBoostIsClamped() {
        let planner = makePlanner()

        let plan = planner.plan(scene: .commuteHurry, motion: .walking, cadence: 500)

        XCTAssertEqual(plan.baseBPM, 126, accuracy: 0.01)
        XCTAssertEqual(plan.beatLevel, 1, accuracy: 0.01)
    }

    func testIdleMotionReducesBeatAndRaisesPadAndReverb() {
        let planner = makePlanner()

        let plan = planner.plan(scene: .sunnyWalk, motion: .idle, cadence: nil)

        XCTAssertEqual(plan.padLevel, 0.55, accuracy: 0.01)
        XCTAssertEqual(plan.beatLevel, 0.22, accuracy: 0.01)
        XCTAssertEqual(plan.reverb, 0.55, accuracy: 0.01)
    }

    func testRunningMotionAddsMoreRhythmicEnergyThanWalking() {
        let planner = makePlanner()

        let walking = planner.plan(scene: .sunnyWalk, motion: .walking, cadence: 120)
        let running = planner.plan(scene: .sunnyWalk, motion: .running, cadence: 120)

        XCTAssertGreaterThan(running.beatLevel, walking.beatLevel)
        XCTAssertGreaterThan(running.arpLevel, walking.arpLevel)
        XCTAssertLessThan(running.reverb, walking.reverb)
    }

    private func makePlanner() -> ScorePlanner {
        ScorePlanner(presets: [
            SceneScorePreset(
                scene: .commuteHurry,
                plan: ScorePlan(
                    padLevel: 0.4,
                    arpLevel: 0.7,
                    beatLevel: 0.9,
                    fxLevel: 0.5,
                    fieldNoiseLevel: 0.3,
                    baseBPM: 120,
                    tempoFollowRate: 0.6,
                    filter: 0.75,
                    reverb: 0.3
                )
            ),
            SceneScorePreset(
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
        ])
    }
}
