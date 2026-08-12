import Foundation

protocol GeoTagProviderType {
    var currentTag: GeoTag { get }
}

protocol TimeProviderType {
    var currentBand: TimeBand { get }
}

protocol WeatherProviderType {
    var currentWeather: WeatherState { get }
}

@MainActor
protocol MotionProviderType {
    var currentMotion: MotionState { get }
    var cadence: Int? { get }
    func start()
    func stop()
}

struct DefaultTimeProvider: TimeProviderType {
    var currentBand: TimeBand {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .morning
        case 11..<17: return .daytime
        case 17..<22: return .evening
        default: return .night
        }
    }
}

struct MockWeatherProvider: WeatherProviderType {
    var currentWeather: WeatherState = .clear
}

@MainActor
struct MockMotionProvider: MotionProviderType {
    var currentMotion: MotionState = .idle
    var cadence: Int? = nil

    func start() {}
    func stop() {}
}
