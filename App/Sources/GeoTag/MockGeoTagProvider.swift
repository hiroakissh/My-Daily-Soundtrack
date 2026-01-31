import Foundation

final class MockGeoTagProvider: GeoTagProvider {
    enum Mode: Equatable {
        case fixed(GeoTag)
        case geofence
    }

    struct Geofence: Equatable {
        let center: GeoCoordinate
        let radius: Double
        let tag: GeoTag
    }

    private let geofences: [Geofence]
    private var continuation: AsyncStream<GeoTag>.Continuation?
    private(set) var currentTag: GeoTag?
    private(set) var mode: Mode

    init(
        mode: Mode = .geofence,
        geofences: [Geofence] = MockGeoTagProvider.defaultGeofences
    ) {
        self.mode = mode
        self.geofences = geofences
    }

    func start() -> AsyncStream<GeoTag> {
        AsyncStream { continuation in
            self.continuation = continuation
            if let tag = currentTag {
                continuation.yield(tag)
            } else {
                evaluateInitialTag()
            }
        }
    }

    func stop() {
        continuation?.finish()
        continuation = nil
    }

    func updateLocation(_ coordinate: GeoCoordinate) {
        guard mode == .geofence else { return }
        let nextTag = geofences.first { geofence in
            let distance = Self.distance(from: coordinate, to: geofence.center)
            return distance <= geofence.radius
        }?.tag ?? .urban
        switchTagIfNeeded(nextTag)
    }

    func setFixedTag(_ tag: GeoTag) {
        mode = .fixed(tag)
        switchTagIfNeeded(tag)
    }

    func resumeGeofenceMode() {
        mode = .geofence
        evaluateInitialTag()
    }

    private func evaluateInitialTag() {
        switch mode {
        case let .fixed(tag):
            switchTagIfNeeded(tag)
        case .geofence:
            switchTagIfNeeded(.urban)
        }
    }

    private func switchTagIfNeeded(_ tag: GeoTag) {
        guard currentTag != tag else { return }
        currentTag = tag
        continuation?.yield(tag)
    }

    private static func distance(from lhs: GeoCoordinate, to rhs: GeoCoordinate) -> Double {
        let lat = lhs.latitude - rhs.latitude
        let lon = lhs.longitude - rhs.longitude
        return (lat * lat + lon * lon).squareRoot() * 111_000
    }

    /// Default geofence set used for mock classification.
    /// These sample areas provide predictable tag switches in development
    /// without CoreLocation or real-world geofencing data.
    static let defaultGeofences: [Geofence] = [
        Geofence(center: GeoCoordinate(latitude: 35.681236, longitude: 139.767125), radius: 500, tag: .station),
        Geofence(center: GeoCoordinate(latitude: 35.685175, longitude: 139.752799), radius: 420, tag: .park),
        Geofence(center: GeoCoordinate(latitude: 35.658034, longitude: 139.701636), radius: 380, tag: .cafe),
        Geofence(center: GeoCoordinate(latitude: 35.671669, longitude: 139.725549), radius: 700, tag: .river)
    ]
}
