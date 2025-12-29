import Combine
import Foundation

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)

    var label: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .playing: return "playing"
        case .paused: return "paused"
        case .error: return "error"
        }
    }
}

final class PlaybackStore: ObservableObject {
    @Published private(set) var state: PlaybackState = .idle

    private let renderer: any AudioRendering
    private var currentTag: GeoTag
    private var cancellables = Set<AnyCancellable>()

    init(renderer: some AudioRendering, initialTag: GeoTag = .urban, tagPublisher: AnyPublisher<GeoTag, Never>? = nil) {
        self.renderer = renderer
        self.currentTag = initialTag
        if let tagPublisher {
            bindTagPublisher(tagPublisher)
        }
    }

    func bindTagPublisher(_ publisher: AnyPublisher<GeoTag, Never>) {
        cancellables.removeAll()
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tag in
                guard let self else { return }
                self.currentTag = tag
                Task { await self.renderer.update(tag: tag) }
            }
            .store(in: &cancellables)
    }

    func start() {
        guard state != .loading else { return }
        state = .loading
        Task { [weak self] in
            guard let self else { return }
            do {
                try await renderer.start(tag: currentTag)
                await MainActor.run {
                    self.state = .playing
                }
            } catch {
                await MainActor.run {
                    self.state = .error("オーディオの初期化に失敗しました")
                }
            }
        }
    }

    func pause() {
        guard state == .playing else { return }
        Task { [weak self] in
            guard let self else { return }
            await renderer.pause()
            await MainActor.run {
                self.state = .paused
            }
        }
    }

    func stop() {
        Task { [weak self] in
            guard let self else { return }
            await renderer.stop()
            await MainActor.run {
                self.state = .idle
            }
        }
    }

    func fail(message: String) {
        state = .error(message)
    }
}
