import XCTest
@testable import MyDailySoundtrack

final class SceneClassifierTests: XCTestCase {
    func testDoubleHitLocksSceneAndExposesCandidateDuringLock() {
        let start = Date(timeIntervalSince1970: 0)
        let classifier = SceneClassifier(startDate: start, lockDuration: 60)
        let sunnyWalk = makeSnapshot(weather: .clear, motion: .walking, cadence: 90)

        let first = classifier.classify(snapshot: sunnyWalk, now: start.addingTimeInterval(5))
        XCTAssertNil(first.current)
        XCTAssertEqual(first.candidate, .sunnyWalk)

        let second = classifier.classify(snapshot: sunnyWalk, now: start.addingTimeInterval(15))
        XCTAssertEqual(second.current, .sunnyWalk)
        XCTAssertEqual(second.lockRemaining ?? -1, 60, accuracy: 0.01)

        let rainyWalk = makeSnapshot(weather: .rainy, motion: .walking, cadence: 80)
        let locked = classifier.classify(snapshot: rainyWalk, now: start.addingTimeInterval(25))
        XCTAssertEqual(locked.current, .sunnyWalk)
        XCTAssertEqual(locked.candidate, .rainyWalk)
    }

    func testMorningIntroExpiresBeforeCommuteRuleIsSelected() {
        let start = Date(timeIntervalSince1970: 0)
        let classifier = SceneClassifier(startDate: start, lockDuration: 60)
        let commute = makeSnapshot(
            geoTag: .station,
            timeBand: .morning,
            weather: .clear,
            motion: .walking,
            cadence: 120
        )

        let opening = classifier.classify(snapshot: commute, now: start.addingTimeInterval(1))
        XCTAssertEqual(opening.candidate, .morningIntro)

        let afterOpening = classifier.classify(snapshot: commute, now: start.addingTimeInterval(61))
        XCTAssertNil(afterOpening.current)
        XCTAssertEqual(afterOpening.candidate, .commuteHurry)

        let confirmed = classifier.classify(snapshot: commute, now: start.addingTimeInterval(62))
        XCTAssertEqual(confirmed.current, .commuteHurry)
    }

    func testLockExpiryRequiresAnotherDoubleHit() {
        let start = Date(timeIntervalSince1970: 0)
        let classifier = SceneClassifier(startDate: start, lockDuration: 60)
        let sunnyWalk = makeSnapshot(weather: .clear, motion: .walking, cadence: 90)
        let rainyWalk = makeSnapshot(weather: .rainy, motion: .walking, cadence: 80)

        _ = classifier.classify(snapshot: sunnyWalk, now: start)
        _ = classifier.classify(snapshot: sunnyWalk, now: start.addingTimeInterval(1))

        let firstAfterLock = classifier.classify(snapshot: rainyWalk, now: start.addingTimeInterval(61))
        XCTAssertEqual(firstAfterLock.current, .sunnyWalk)
        XCTAssertEqual(firstAfterLock.candidate, .rainyWalk)

        let secondAfterLock = classifier.classify(snapshot: rainyWalk, now: start.addingTimeInterval(62))
        XCTAssertEqual(secondAfterLock.current, .rainyWalk)
    }

    private func makeSnapshot(
        geoTag: GeoTag = .urban,
        timeBand: TimeBand = .daytime,
        weather: WeatherState,
        motion: MotionState,
        cadence: Int?
    ) -> ContextSnapshot {
        ContextSnapshot(
            geoTag: geoTag,
            timeBand: timeBand,
            weather: weather,
            motion: motion,
            cadence: cadence,
            timestamp: Date()
        )
    }
}
