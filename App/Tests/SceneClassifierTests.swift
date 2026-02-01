import XCTest
@testable import MyDailySoundtrack

final class SceneClassifierTests: XCTestCase {
    func testDoubleHitLocksScene() {
        let start = Date(timeIntervalSince1970: 0)
        let classifier = SceneClassifier(startDate: start, lockDuration: 60, contextTimeout: 30, initialScene: .natureAmbient)
        let context = makeContext(
            geoTag: .urban,
            timeBand: .afternoon,
            weatherCondition: .sunny,
            activity: .walking,
            cadence: 90
        )

        let first = classifier.update(context: context, now: start.addingTimeInterval(5))
        XCTAssertEqual(first.current, .natureAmbient)

        let second = classifier.update(context: context, now: start.addingTimeInterval(15))
        XCTAssertEqual(second.current, .sunnyWalk)
        XCTAssertNotNil(second.lockRemaining)

        let rainyContext = makeContext(
            geoTag: .urban,
            timeBand: .afternoon,
            weatherCondition: .rainy,
            activity: .walking,
            cadence: 80
        )
        let locked = classifier.update(context: rainyContext, now: start.addingTimeInterval(25))
        XCTAssertEqual(locked.current, .sunnyWalk)
    }

    func testFallbackAfterTimeoutUsesLastSnapshot() {
        let start = Date(timeIntervalSince1970: 0)
        let classifier = SceneClassifier(startDate: start, lockDuration: 60, contextTimeout: 30, initialScene: .natureAmbient)
        let context = makeContext(
            geoTag: .urban,
            timeBand: .evening,
            weatherCondition: .sunny,
            activity: .walking,
            cadence: 80
        )

        _ = classifier.update(context: context, now: start.addingTimeInterval(2))

        let evaluation = classifier.update(context: nil, now: start.addingTimeInterval(40))
        XCTAssertEqual(evaluation.current, .sunnyWalk)
        XCTAssertNotNil(evaluation.lockRemaining)
    }

    private func makeContext(
        geoTag: GeoTag,
        timeBand: TimeBand,
        weatherCondition: WeatherState.Condition,
        activity: MotionState.Activity,
        cadence: Double
    ) -> ContextSnapshot {
        ContextSnapshot(
            geoTag: geoTag,
            timeBand: timeBand,
            weather: WeatherState(condition: weatherCondition, temperature: 18, precipitation: 0.1),
            motion: MotionState(activity: activity, speed: 1.2, cadence: cadence),
            timestamp: Date()
        )
    }
}
