import Foundation

struct AppContainer {
    let geoTagProvider: GeoTagProvider
    let timeProvider: TimeProvider
    let weatherProvider: WeatherProvider
    let motionProvider: MotionProvider
    let audioRenderer: AudioRenderer

    static func live() -> AppContainer {
        AppContainer(
            geoTagProvider: CoreLocationGeoTagProvider(),
            timeProvider: SystemTimeProvider(),
            weatherProvider: WeatherKitWeatherProvider(),
            motionProvider: CoreMotionMotionProvider(),
            audioRenderer: SimpleAudioRenderer()
        )
    }

    static func mocked(
        geoTagProvider: GeoTagProvider = MockGeoTagProvider(mode: .fixed(.urban)),
        timeProvider: TimeProvider = FixedTimeProvider(band: .morning),
        weatherProvider: WeatherProvider = StaticWeatherProvider(
            weather: WeatherState(condition: .sunny, temperature: 20, precipitation: 0)
        ),
        motionProvider: MotionProvider = StaticMotionProvider(
            motion: MotionState(activity: .walking, speed: 1.1, cadence: 100)
        ),
        audioRenderer: AudioRenderer = StubAudioRenderer()
    ) -> AppContainer {
        AppContainer(
            geoTagProvider: geoTagProvider,
            timeProvider: timeProvider,
            weatherProvider: weatherProvider,
            motionProvider: motionProvider,
            audioRenderer: audioRenderer
        )
    }

    func makeContextAggregator(pollInterval: TimeInterval = 10) -> ContextAggregator {
        ContextAggregator(
            geoTagProvider: geoTagProvider,
            timeProvider: timeProvider,
            weatherProvider: weatherProvider,
            motionProvider: motionProvider,
            pollInterval: pollInterval
        )
    }
}
