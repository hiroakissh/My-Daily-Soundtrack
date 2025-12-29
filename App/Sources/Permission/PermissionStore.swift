import Foundation
import SwiftUI
#if os(iOS)
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
        requestHandler: @escaping RequestHandler = PermissionStore.mockRequestHandler,
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
    static let mockRequestHandler: RequestHandler = {
        try? await Task.sleep(for: .milliseconds(400))
        return .denied
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
