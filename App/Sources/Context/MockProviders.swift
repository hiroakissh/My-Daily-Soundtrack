import Foundation

struct FixedTimeProvider: TimeProvider {
    let band: TimeBand

    func timeBand(for date: Date) -> TimeBand {
        band
    }
}

final class StaticWeatherProvider: WeatherProvider {
    var weather: WeatherState

    init(weather: WeatherState) {
        self.weather = weather
    }

    func fetchWeather() async -> WeatherState? {
        weather
    }
}

final class StaticMotionProvider: MotionProvider {
    var motion: MotionState

    init(motion: MotionState) {
        self.motion = motion
    }

    func fetchMotion() async -> MotionState? {
        motion
    }
}
