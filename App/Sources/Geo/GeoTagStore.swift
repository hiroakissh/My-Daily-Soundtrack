import Combine
import Foundation

enum GeoTag: String, CaseIterable {
    case station
    case park
    case cafe
    case river
    case forest
    case urban
}

final class GeoTagStore: ObservableObject {
    @Published private(set) var currentTag: GeoTag = .urban

    private var provider: (any GeoTagProviding)?
    private var cancellables = Set<AnyCancellable>()

    init(provider: (any GeoTagProviding)? = nil) {
        self.provider = provider
        bindProvider()
    }

    func setProvider(_ provider: some GeoTagProviding) {
        self.provider = provider
        bindProvider()
    }

    private func bindProvider() {
        cancellables.removeAll()
        guard let provider else { return }
        provider.tagPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTag)
    }

    @discardableResult
    func start() async -> GeoTag {
        if let provider {
            await provider.start()
            return provider.currentTag
        }
        return currentTag
    }

    func stop() {
        provider?.stop()
    }

    // Dev helper for manual cycling when no provider is attached.
    func cycleNext() {
        guard provider == nil else { return }
        guard let index = GeoTag.allCases.firstIndex(of: currentTag) else { return }
        let next = GeoTag.allCases[(index + 1) % GeoTag.allCases.count]
        currentTag = next
    }
}

extension GeoTagStore {
    static func mock() -> GeoTagStore {
        let provider = MockGeoTagProvider()
        return GeoTagStore(provider: provider)
    }
}
