import Foundation

protocol TimeProvider {
    func timeBand(for date: Date) -> TimeBand
}

protocol WeatherProvider {
    func fetchWeather() async -> WeatherState?
}

protocol MotionProvider {
    func fetchMotion() async -> MotionState?
}

struct SystemTimeProvider: TimeProvider {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func timeBand(for date: Date) -> TimeBand {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<11:
            return .morning
        case 11..<16:
            return .afternoon
        case 16..<20:
            return .evening
        default:
            return .night
        }
    }
}

@MainActor
final class ContextAggregator {
    private let geoTagProvider: GeoTagProvider
    private let timeProvider: TimeProvider
    private let weatherProvider: WeatherProvider
    private let motionProvider: MotionProvider
    private let pollInterval: TimeInterval

    private var pollingTask: Task<Void, Never>?
    private var geoTagTask: Task<Void, Never>?
    private var continuation: AsyncStream<ContextSnapshot>.Continuation?

    private var currentGeoTag: GeoTag?
    private var lastWeather: WeatherState?
    private var lastMotion: MotionState?
    private var cadenceSmoother = CadenceSmoother()

    private(set) var latestSnapshot: ContextSnapshot?

    init(
        geoTagProvider: GeoTagProvider,
        timeProvider: TimeProvider,
        weatherProvider: WeatherProvider,
        motionProvider: MotionProvider,
        pollInterval: TimeInterval = 10
    ) {
        self.geoTagProvider = geoTagProvider
        self.timeProvider = timeProvider
        self.weatherProvider = weatherProvider
        self.motionProvider = motionProvider
        self.pollInterval = pollInterval
    }

    func start() -> AsyncStream<ContextSnapshot> {
        if pollingTask == nil {
            startGeoTagUpdates()
            startPolling()
        }

        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { [weak self] _ in
                self?.continuation = nil
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        geoTagTask?.cancel()
        geoTagTask = nil
        geoTagProvider.stop()
        continuation?.finish()
        continuation = nil
    }

    private func startGeoTagUpdates() {
        geoTagTask?.cancel()
        geoTagTask = Task { [weak self] in
            guard let self else { return }
            for await tag in geoTagProvider.start() {
                await MainActor.run {
                    self.currentGeoTag = tag
                }
            }
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.pollOnce()
                do {
                    try await Task.sleep(for: .seconds(self.pollInterval))
                } catch {
                    return
                }
            }
        }
    }

    private func pollOnce() async {
        let now = Date()
        let timeBand = timeProvider.timeBand(for: now)
        let weather = await weatherProvider.fetchWeather() ?? lastWeather ?? WeatherState(
            condition: .sunny,
            temperature: 20,
            precipitation: 0
        )
        lastWeather = weather

        var motion = await motionProvider.fetchMotion() ?? lastMotion ?? MotionState(
            activity: .stopped,
            speed: 0,
            cadence: 0
        )

        motion = MotionState(
            activity: motion.activity,
            speed: motion.speed,
            cadence: cadenceSmoother.smooth(motion.cadence)
        )
        lastMotion = motion

        let geoTag = currentGeoTag ?? geoTagProvider.currentTag ?? latestSnapshot?.geoTag ?? .urban

        let snapshot = ContextSnapshot(
            geoTag: geoTag,
            timeBand: timeBand,
            weather: weather,
            motion: motion,
            timestamp: now
        )
        latestSnapshot = snapshot
        continuation?.yield(snapshot)
    }
}

private struct CadenceSmoother {
    private var samples: [Double] = []
    private let maxSamples = 3
    private let spikeThreshold = 40.0

    mutating func smooth(_ cadence: Double) -> Double {
        let normalized = max(0, cadence)
        guard let average = average else {
            append(normalized)
            return normalized
        }

        if abs(normalized - average) > spikeThreshold {
            return average
        }

        append(normalized)
        return average ?? normalized
    }

    private var average: Double? {
        guard !samples.isEmpty else { return nil }
        return samples.reduce(0, +) / Double(samples.count)
    }

    private mutating func append(_ value: Double) {
        samples.append(value)
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
    }
}
