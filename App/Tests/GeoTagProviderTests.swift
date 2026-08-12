import XCTest
@testable import MyDailySoundtrack

@MainActor
final class GeoTagProviderTests: XCTestCase {
    func testSimpleProviderSelectsMatchingFence() {
        let provider = SimpleGeoTagProvider(
            fences: [GeoFence(tag: .park, latitude: 35.000, longitude: 139.000, radiusMeters: 150)]
        )

        provider.updateLocation(latitude: 35.0005, longitude: 139.0005)

        XCTAssertEqual(provider.currentTag, .park)
    }

    func testSimpleProviderKeepsCurrentTagWhenNoFenceMatches() {
        let provider = SimpleGeoTagProvider(
            fences: [GeoFence(tag: .park, latitude: 35.000, longitude: 139.000, radiusMeters: 50)]
        )

        provider.updateLocation(latitude: 36.000, longitude: 140.000)

        XCTAssertEqual(provider.currentTag, .urban)
    }
}
