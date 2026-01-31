import Foundation

enum GeoTag: String, CaseIterable, Equatable {
    case station
    case park
    case cafe
    case river
    case forest
    case urban
}

struct GeoCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}
