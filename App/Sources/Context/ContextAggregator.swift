import Combine
import Foundation

final class ContextAggregator: ObservableObject {
    @Published private(set) var snapshot: ContextSnapshot

    private let geoProvider: GeoTagStore
    private let timeProvider: TimeProviderType
    private let weatherProvider: WeatherProviderType
    private let motionProvider: MotionProviderType
    private var timerCancellable: AnyCancellable?

    init(
        geoProvider: GeoTagStore,
        timeProvider: TimeProviderType = DefaultTimeProvider(),
        weatherProvider: WeatherProviderType = MockWeatherProvider(),
        motionProvider: MotionProviderType = MockMotionProvider()
    ) {
        self.geoProvider = geoProvider
        self.timeProvider = timeProvider
        self.weatherProvider = weatherProvider
        self.motionProvider = motionProvider
        self.snapshot = ContextSnapshot(
            geoTag: geoProvider.currentTag,
            timeBand: timeProvider.currentBand,
            weather: weatherProvider.currentWeather,
            motion: motionProvider.currentMotion,
            cadence: motionProvider.cadence,
            timestamp: Date()
        )
    }

    func start(pollInterval: TimeInterval = 10) {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: pollInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateSnapshot()
            }
        updateSnapshot()
    }

    func stop() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func updateSnapshot() {
        let newSnapshot = ContextSnapshot(
            geoTag: geoProvider.currentTag,
            timeBand: timeProvider.currentBand,
            weather: weatherProvider.currentWeather,
            motion: motionProvider.currentMotion,
            cadence: motionProvider.cadence,
            timestamp: Date()
        )
        snapshot = newSnapshot
    }
}

#Preview("Context Aggregator") {
    let geoStore = GeoTagStore(provider: MockGeoTagProvider())
    let aggregator = ContextAggregator(
        geoProvider: geoStore,
        timeProvider: DefaultTimeProvider(),
        weatherProvider: MockWeatherProvider(),
        motionProvider: MockMotionProvider(currentMotion: .walking, cadence: 104)
    )
    aggregator.start(pollInterval: 2)
    return VStack(alignment: .leading, spacing: 8) {
        Text("GeoTag: \(aggregator.snapshot.geoTag.rawValue)")
        Text("Time: \(aggregator.snapshot.timeBand.rawValue)")
        Text("Weather: \(aggregator.snapshot.weather.rawValue)")
        Text("Motion: \(aggregator.snapshot.motion.rawValue)")
        Text("Cadence: \(aggregator.snapshot.cadence ?? 0)")
        Text("Timestamp: \(aggregator.snapshot.timestamp.formatted())")
    }
    .padding()
}
