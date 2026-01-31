import Foundation
import SwiftUI
#if os(iOS)
import CoreLocation
import UIKit
#endif

enum PermissionStatus: Equatable {
    case awaitingConsent
    case requesting
    case granted
    case denied
    case restricted
}

final class PermissionStore: ObservableObject {
    @Published private(set) var status: PermissionStatus = .awaitingConsent

    typealias RequestHandler = () async -> PermissionStatus
    typealias OpenSettingsHandler = () -> Void

    private let requestHandler: RequestHandler
    private let openSettingsHandler: OpenSettingsHandler

    init(
        requestHandler: @escaping RequestHandler = PermissionStore.defaultRequestHandler,
        openSettingsHandler: @escaping OpenSettingsHandler = PermissionStore.defaultOpenSettings
    ) {
        self.requestHandler = requestHandler
        self.openSettingsHandler = openSettingsHandler
    }

    @MainActor
    func requestPermission() {
        guard status != .requesting else { return }
        status = .requesting

        Task { [weak self] in
            guard let self else { return }
            let result = await requestHandler()
            await MainActor.run {
                self.status = result
            }
        }
    }

    func openSettings() {
        openSettingsHandler()
    }
}

// MARK: - Defaults

private extension PermissionStore {
    static let defaultRequestHandler: RequestHandler = {
        #if os(iOS)
        let requester = LocationPermissionRequester()
        return await requester.requestAuthorization()
        #else
        try? await Task.sleep(for: .milliseconds(400))
        return .denied
        #endif
    }

    static let defaultOpenSettings: OpenSettingsHandler = {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        #endif
    }
}

#if os(iOS)
private final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<PermissionStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestAuthorization() async -> PermissionStatus {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        @unknown default:
            return .denied
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation else { return }
        continuation.resume(returning: mapStatus(manager.authorizationStatus))
        self.continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard let continuation else { return }
        continuation.resume(returning: mapStatus(status))
        self.continuation = nil
    }

    private func mapStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .awaitingConsent
        @unknown default:
            return .denied
        }
    }
}
#endif
