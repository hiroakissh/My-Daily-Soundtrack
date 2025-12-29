import Foundation

enum TimeBand: String, CaseIterable {
    case morning
    case daytime
    case evening
    case night
}

enum WeatherState: String, CaseIterable {
    case clear
    case cloudy
    case rainy
    case snowy
    case unknown
}

enum MotionState: String, CaseIterable {
    case idle
    case walking
    case running
}

struct ContextSnapshot: Equatable {
    var geoTag: GeoTag
    var timeBand: TimeBand
    var weather: WeatherState
    var motion: MotionState
    var cadence: Int?
    var timestamp: Date
}
