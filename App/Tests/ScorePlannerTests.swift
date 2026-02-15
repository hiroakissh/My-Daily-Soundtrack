import XCTest
@testable import MyDailySoundtrack

final class ScorePlannerTests: XCTestCase {
    func testCadenceClampsToProfileRange() {
        let planner = ScorePlanner()
        let start = Date(timeIntervalSince1970: 0)
        let context = makeContext(activity: .walking, cadence: 500)

        let plan = planner.plan(scene: .commuteHurry, context: context, now: start)

        XCTAssertEqual(plan.baseBPM, 132, accuracy: 0.01)
    }

    func testStoppedMotionFadesBeatAndBoostsPad() {
        let planner = ScorePlanner()
        let start = Date(timeIntervalSince1970: 0)
        let context = makeContext(activity: .stopped, cadence: 0)

        let initialPlan = planner.plan(scene: .sunnyWalk, context: context, now: start)
        let fadedPlan = planner.plan(scene: .sunnyWalk, context: context, now: start.addingTimeInterval(3))

        XCTAssertGreaterThan(initialPlan.level(for: .beat), 0)
        XCTAssertEqual(fadedPlan.level(for: .beat), 0, accuracy: 0.01)
        XCTAssertEqual(fadedPlan.level(for: .pad), initialPlan.level(for: .pad), accuracy: 0.01)
    }

    func testSceneTransitionInterpolatesPlans() {
        let planner = ScorePlanner()
        let start = Date(timeIntervalSince1970: 0)
        let context = makeContext(activity: .walking, cadence: 90)

        let initial = planner.plan(scene: .sunnyWalk, context: context, now: start)
        _ = planner.plan(scene: .rainyWalk, context: context, now: start.addingTimeInterval(1))
        let blended = planner.plan(scene: .rainyWalk, context: context, now: start.addingTimeInterval(3))

        let targetPlanner = ScorePlanner()
        let target = targetPlanner.plan(scene: .rainyWalk, context: context, now: start)

        XCTAssertLessThan(blended.baseBPM, initial.baseBPM)
        XCTAssertGreaterThan(blended.baseBPM, target.baseBPM)
    }

    func testMorningIntroBuildScalesBeatAndArp() {
        let planner = ScorePlanner()
        let start = Date(timeIntervalSince1970: 0)
        let context = makeContext(activity: .walking, cadence: 0)

        let early = planner.plan(scene: .morningIntro, context: context, now: start)
        XCTAssertEqual(early.level(for: .beat), 0, accuracy: 0.01)
        XCTAssertEqual(early.level(for: .arp), 0, accuracy: 0.01)

        let later = planner.plan(scene: .morningIntro, context: context, now: start.addingTimeInterval(45))
        XCTAssertEqual(later.level(for: .beat), 0.15, accuracy: 0.01)
        XCTAssertEqual(later.level(for: .arp), 0.175, accuracy: 0.01)
    }

    private func makeContext(activity: MotionState.Activity, cadence: Double) -> ContextSnapshot {
        ContextSnapshot(
            geoTag: .urban,
            timeBand: .afternoon,
            weather: WeatherState(condition: .sunny, temperature: 22, precipitation: 0),
            motion: MotionState(activity: activity, speed: 1.2, cadence: cadence),
            timestamp: Date()
        )
    }
}
