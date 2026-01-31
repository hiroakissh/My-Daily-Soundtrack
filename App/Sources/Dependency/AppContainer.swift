import Foundation

struct AppContainer {
    let geoTagProvider: GeoTagProvider
    let audioRenderer: AudioRenderer

    static func live() -> AppContainer {
        AppContainer(
            geoTagProvider: MockGeoTagProvider(),
            audioRenderer: StubAudioRenderer()
        )
    }

    static func mocked(
        geoTagProvider: GeoTagProvider = MockGeoTagProvider(mode: .fixed(.urban)),
        audioRenderer: AudioRenderer = StubAudioRenderer()
    ) -> AppContainer {
        AppContainer(
            geoTagProvider: geoTagProvider,
            audioRenderer: audioRenderer
        )
    }
}
