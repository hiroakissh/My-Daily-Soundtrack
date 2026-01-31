import CoreLocation
import Foundation

final class CoreLocationGeoTagProvider: NSObject, GeoTagProvider {
    struct Geofence: Equatable {
        let center: CLLocationCoordinate2D
        let radius: CLLocationDistance
        let tag: GeoTag
    }

    private let locationManager: CLLocationManager
    private let geofences: [Geofence]
    private let distanceThreshold: CLLocationDistance
    private let hysteresisDuration: TimeInterval
    private var continuation: AsyncStream<GeoTag>.Continuation?
    private var pendingTask: Task<Void, Never>?
    private var pendingTag: GeoTag?
    private var lastLocation: CLLocation?

    private(set) var currentTag: GeoTag?

    init(
        geofences: [Geofence] = CoreLocationGeoTagProvider.defaultGeofences,
        distanceThreshold: CLLocationDistance = 60,
        hysteresisDuration: TimeInterval = 3.0
    ) {
        self.locationManager = CLLocationManager()
        self.geofences = geofences
        self.distanceThreshold = distanceThreshold
        self.hysteresisDuration = hysteresisDuration
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = distanceThreshold
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    func start() -> AsyncStream<GeoTag> {
        AsyncStream { continuation in
            self.continuation = continuation
            if let tag = currentTag {
                continuation.yield(tag)
            }
            let status = CLLocationManager.authorizationStatus()
            handleAuthorization(status)
        }
    }

    func stop() {
        pendingTask?.cancel()
        pendingTask = nil
        pendingTag = nil
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        continuation?.finish()
        continuation = nil
    }

    private func handleAuthorization(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    private func startLocationUpdates() {
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.startUpdatingLocation()
        if let location = locationManager.location {
            handleLocation(location)
        }
    }

    private func handleLocation(_ location: CLLocation) {
        guard shouldProcess(location) else { return }
        lastLocation = location
        let nextTag = tag(for: location.coordinate)
        scheduleTagSwitch(nextTag)
    }

    private func shouldProcess(_ location: CLLocation) -> Bool {
        guard let lastLocation else { return true }
        return location.distance(from: lastLocation) >= distanceThreshold
    }

    private func tag(for coordinate: CLLocationCoordinate2D) -> GeoTag {
        geofences.first { geofence in
            let centerLocation = CLLocation(latitude: geofence.center.latitude, longitude: geofence.center.longitude)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            return location.distance(from: centerLocation) <= geofence.radius
        }?.tag ?? .urban
    }

    private func scheduleTagSwitch(_ tag: GeoTag) {
        guard currentTag != tag else {
            pendingTask?.cancel()
            pendingTag = nil
            return
        }
        guard pendingTag != tag else { return }
        pendingTask?.cancel()
        pendingTag = tag
        pendingTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(hysteresisDuration))
            guard !Task.isCancelled else { return }
            applyTag(tag)
        }
    }

    private func applyTag(_ tag: GeoTag) {
        guard currentTag != tag else { return }
        currentTag = tag
        pendingTag = nil
        continuation?.yield(tag)
    }

    static let defaultGeofences: [Geofence] = [
        Geofence(center: CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125), radius: 500, tag: .station),
        Geofence(center: CLLocationCoordinate2D(latitude: 35.685175, longitude: 139.752799), radius: 420, tag: .park),
        Geofence(center: CLLocationCoordinate2D(latitude: 35.658034, longitude: 139.701636), radius: 380, tag: .cafe),
        Geofence(center: CLLocationCoordinate2D(latitude: 35.671669, longitude: 139.725549), radius: 700, tag: .river)
    ]
}

extension CoreLocationGeoTagProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorization(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorization(status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        handleLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let tag = currentTag {
            continuation?.yield(tag)
        }
    }
}
