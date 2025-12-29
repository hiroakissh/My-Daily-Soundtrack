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

    func start() {
        guard state != .loading else { return }
        state = .loading
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(350))
            await MainActor.run {
                // In real implementation, check for errors from AudioRenderer.
                self.state = .playing
            }
        }
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func fail(message: String) {
        state = .error(message)
    }
}
