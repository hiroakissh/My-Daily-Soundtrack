import Foundation

protocol WeatherProviding {
    var current: WeatherState { get }
    func refresh() async throws -> WeatherState
}

final class MockWeatherProvider: WeatherProviding {
    private(set) var current: WeatherState

    init(current: WeatherState = .clear) {
        self.current = current
    }

    func refresh() async throws -> WeatherState {
        // Rotate through a simple sequence for development.
        let sequence: [WeatherState] = [.clear, .cloudy, .rainy, .clear]
        if let idx = sequence.firstIndex(of: current) {
            current = sequence[(idx + 1) % sequence.count]
        } else {
            current = .clear
        }
        return current
    }
}

#if os(iOS)
/// Placeholder for WeatherKit or external API integration.
final class WeatherKitProvider: WeatherProviding {
    private(set) var current: WeatherState = .unknown

    func refresh() async throws -> WeatherState {
        // TODO: Integrate WeatherKit; for now return placeholder.
        current = .unknown
        return current
    }
}
#endif
