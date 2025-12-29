import Combine
import Foundation

protocol GeoTagProviding: AnyObject {
    var currentTag: GeoTag { get }
    var tagPublisher: AnyPublisher<GeoTag, Never> { get }
    func start() async
    func stop()
}

struct GeoFence {
    let tag: GeoTag
    let latitude: Double
    let longitude: Double
    let radiusMeters: Double
}

final class MockGeoTagProvider: GeoTagProviding {
    private let subject = CurrentValueSubject<GeoTag, Never>(.urban)
    private var task: Task<Void, Never>?

    var currentTag: GeoTag { subject.value }

    var tagPublisher: AnyPublisher<GeoTag, Never> {
        subject.eraseToAnyPublisher()
    }

    func start() async {
        guard task == nil else { return }
        task = Task { [weak self] in
            guard let self else { return }
            let sequence: [GeoTag] = [.urban, .station, .cafe, .park, .urban]
            var index = 0
            while !Task.isCancelled {
                subject.send(sequence[index % sequence.count])
                index += 1
                try? await Task.sleep(for: .seconds(6))
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}

final class SimpleGeoTagProvider: GeoTagProviding {
    private let subject = CurrentValueSubject<GeoTag, Never>(.urban)
    private var fences: [GeoFence]
    private var hysteresisSeconds: TimeInterval
    private var lastSwitchDate: Date = .distantPast

    init(fences: [GeoFence], hysteresisSeconds: TimeInterval = 3) {
        self.fences = fences
        self.hysteresisSeconds = hysteresisSeconds
    }

    var currentTag: GeoTag { subject.value }

    var tagPublisher: AnyPublisher<GeoTag, Never> {
        subject.eraseToAnyPublisher()
    }

    func start() async {
        // No-op for stub; relies on updateLocation to be called.
    }

    func stop() {
        // No-op for stub; hook for CoreLocation stopUpdates.
    }

    func updateLocation(latitude: Double, longitude: Double) {
        guard let matched = matchFence(latitude: latitude, longitude: longitude) else { return }
        guard matched != subject.value || Date().timeIntervalSince(lastSwitchDate) > hysteresisSeconds else {
            return
        }
        lastSwitchDate = Date()
        subject.send(matched)
    }

    private func matchFence(latitude: Double, longitude: Double) -> GeoTag? {
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
}
