import Combine
import CoreLocation
import Foundation

#if os(iOS)
@MainActor
final class CoreLocationGeoTagProvider: NSObject, GeoTagProviding, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let subject = CurrentValueSubject<GeoTag, Never>(.urban)
    private var fences: [GeoFence]
    private var hysteresisSeconds: TimeInterval
    private var lastSwitchDate: Date = .distantPast

    var currentTag: GeoTag { subject.value }

    var tagPublisher: AnyPublisher<GeoTag, Never> {
        subject.eraseToAnyPublisher()
    }

    init(fences: [GeoFence], hysteresisSeconds: TimeInterval = 3) {
        self.fences = fences
        self.hysteresisSeconds = hysteresisSeconds
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 50
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start() async {
        guard manager.authorizationStatus == .authorizedAlways ||
            manager.authorizationStatus == .authorizedWhenInUse else { return }
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    private func updateTag(for location: CLLocation) {
        let matched = matchFence(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        guard matched != subject.value || Date().timeIntervalSince(lastSwitchDate) > hysteresisSeconds else { return }
        lastSwitchDate = Date()
        subject.send(matched)
    }

    private func matchFence(latitude: Double, longitude: Double) -> GeoTag {
        for fence in fences {
            let distance = haversineDistance(
                lat1: latitude,
                lon1: longitude,
                lat2: fence.latitude,
                lon2: fence.longitude
            )
            if distance <= fence.radiusMeters {
                return fence.tag
            }
        }
        return subject.value
    }

    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 6_371_000.0
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) *
            cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateTag(for: location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}

#endif
