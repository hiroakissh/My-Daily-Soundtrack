import XCTest
@testable import MyDailySoundtrack

@MainActor
final class OnboardingPermissionTests: XCTestCase {
    func testOnboardingMovesThroughSlidesAndCompletes() {
        let slides = [
            OnboardingSlide(title: "A", subtitle: "A", heroSymbol: "a.circle", gradient: .init(colors: [.blue], startPoint: .top, endPoint: .bottom)),
            OnboardingSlide(title: "B", subtitle: "B", heroSymbol: "b.circle", gradient: .init(colors: [.green], startPoint: .top, endPoint: .bottom))
        ]
        let store = OnboardingStore(slides: slides)

        store.startIfNeeded()
        XCTAssertEqual(store.currentIndex, 0)
        store.goNext()
        XCTAssertEqual(store.currentIndex, 1)
        XCTAssertTrue(store.isOnLastSlide)
        store.complete()
        XCTAssertTrue(store.isCompleted)
    }

    func testPermissionStorePublishesInjectedDeniedResultAndOpensSettings() async {
        var settingsOpened = false
        let store = PermissionStore(
            requestHandler: { .denied },
            openSettingsHandler: { settingsOpened = true }
        )

        XCTAssertEqual(store.status, .awaitingConsent)
        store.requestPermission()
        try? await Task.sleep(for: .milliseconds(30))

        XCTAssertEqual(store.status, .denied)
        store.openSettings()
        XCTAssertTrue(settingsOpened)
    }

    func testPermissionStoreIgnoresDuplicateRequestsWhileRequesting() async {
        var requestCount = 0
        let store = PermissionStore(
            requestHandler: {
                requestCount += 1
                try? await Task.sleep(for: .milliseconds(20))
                return .granted
            }
        )

        store.requestPermission()
        store.requestPermission()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(store.status, .granted)
    }
}
