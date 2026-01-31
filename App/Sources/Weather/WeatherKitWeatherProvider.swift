import CoreLocation
import Foundation
#if canImport(WeatherKit)
import WeatherKit
#endif

final class WeatherKitWeatherProvider: NSObject, WeatherProvider {
    private let locationManager: CLLocationManager
    private let cacheDuration: TimeInterval
    private let fallback: WeatherState

    private var latestWeather: WeatherState?
    private var latestUpdate: Date?
    private var latestLocation: CLLocation?

    init(
        cacheDuration: TimeInterval = 600,
        fallback: WeatherState = WeatherState(condition: .sunny, temperature: 20, precipitation: 0)
    ) {
        self.locationManager = CLLocationManager()
        self.cacheDuration = cacheDuration
        self.fallback = fallback
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        requestLocationIfNeeded()
    }

    func fetchWeather() async -> WeatherState? {
        if let latestWeather,
           let latestUpdate,
           Date().timeIntervalSince(latestUpdate) < cacheDuration {
            return latestWeather
        }

        guard let location = latestLocation else {
            return latestWeather ?? fallback
        }

        #if canImport(WeatherKit)
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let state = WeatherState(
                condition: mapCondition(weather.currentWeather.condition),
                temperature: weather.currentWeather.temperature.value,
                precipitation: weather.currentWeather.precipitationIntensity.value
            )
            latestWeather = state
            latestUpdate = Date()
            return state
        } catch {
            return latestWeather ?? fallback
        }
        #else
        return latestWeather ?? fallback
        #endif
    }

    private func requestLocationIfNeeded() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    #if canImport(WeatherKit)
    private func mapCondition(_ condition: WeatherCondition) -> WeatherState.Condition {
        switch condition {
        case .clear, .mostlyClear, .hot, .sunFlurries:
            return .sunny
        case .partlyCloudy, .mostlyCloudy, .cloudy, .haze, .smoky, .blowingDust, .breezy, .windy:
            return .cloudy
        case .drizzle, .rain, .heavyRain, .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms,
             .sunShowers, .freezingRain, .hail, .mixedRainAndHail, .sleet:
            return .rainy
        default:
            return .cloudy
        }
    }
    #endif
}

extension WeatherKitWeatherProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocationIfNeeded()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocationIfNeeded()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        latestLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if latestLocation == nil {
            latestLocation = manager.location
        }
    }
}
