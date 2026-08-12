import Foundation
import SwiftUI

#if os(iOS)
import CoreLocation
import UIKit
#endif

enum PermissionStatus: Equatable, Sendable {
    case awaitingConsent
    case requesting
    case granted
    case denied
    case restricted
}

@MainActor
protocol LocationAuthorizationClient: AnyObject {
    var status: PermissionStatus { get }
    func request() async -> PermissionStatus
}

@MainActor
final class PermissionStore: ObservableObject {
    @Published private(set) var status: PermissionStatus

    typealias RequestHandler = @MainActor () async -> PermissionStatus
    typealias OpenSettingsHandler = @MainActor () -> Void

    private let requestHandler: RequestHandler
    private let openSettingsHandler: OpenSettingsHandler
    private let authorizationClient: LocationAuthorizationClient

    init(
        requestHandler: RequestHandler? = nil,
        openSettingsHandler: @escaping OpenSettingsHandler = PermissionStore.defaultOpenSettings,
        authorizationClient: LocationAuthorizationClient? = nil
    ) {
        let client = authorizationClient ?? PermissionStore.makeDefaultAuthorizationClient()
        self.authorizationClient = client
        self.status = client.status
        self.requestHandler = requestHandler ?? { await client.request() }
        self.openSettingsHandler = openSettingsHandler
    }

    func requestPermission() {
        guard status != .requesting else { return }
        status = .requesting

        Task { @MainActor [weak self] in
            guard let self else { return }
            status = await requestHandler()
        }
    }

    func refreshStatus() {
        guard status != .requesting else { return }
        status = authorizationClient.status
    }

    func openSettings() {
        openSettingsHandler()
    }
}

// MARK: - Platform clients

@MainActor
private extension PermissionStore {
    static func makeDefaultAuthorizationClient() -> LocationAuthorizationClient {
        #if os(iOS)
        return CoreLocationAuthorizationClient()
        #else
        return MockLocationAuthorizationClient()
        #endif
    }

    static let defaultOpenSettings: OpenSettingsHandler = {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url, options: [:])
        #endif
    }
}

#if os(iOS)
@MainActor
private final class CoreLocationAuthorizationClient: NSObject, LocationAuthorizationClient, @preconcurrency CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private var pendingContinuation: CheckedContinuation<PermissionStatus, Never>?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        manager.delegate = self
    }

    var status: PermissionStatus {
        Self.map(manager.authorizationStatus)
    }

    func request() async -> PermissionStatus {
        switch status {
        case .granted, .denied, .restricted:
            return status
        case .awaitingConsent, .requesting:
            break
        }

        return await withCheckedContinuation { continuation in
            pendingContinuation = continuation
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let pendingContinuation else { return }
        self.pendingContinuation = nil
        pendingContinuation.resume(returning: status)
    }

    private static func map(_ status: CLAuthorizationStatus) -> PermissionStatus {
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
            return .restricted
        }
    }
}
#else
@MainActor
private final class MockLocationAuthorizationClient: LocationAuthorizationClient {
    var status: PermissionStatus = .awaitingConsent

    func request() async -> PermissionStatus {
        .granted
    }
}
#endif
