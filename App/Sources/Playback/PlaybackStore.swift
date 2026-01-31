import Foundation

enum PlaybackError: Equatable {
    case locationUnavailable
    case audioFailure
}

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(PlaybackError)
}

@MainActor
final class PlaybackStore: ObservableObject {
    @Published private(set) var state: PlaybackState = .idle
    @Published private(set) var currentTag: GeoTag?

    private let geoTagProvider: GeoTagProvider
    private let audioRenderer: AudioRenderer
    private var tagTask: Task<Void, Never>?
    private var playbackTask: Task<Void, Never>?

    init(geoTagProvider: GeoTagProvider, audioRenderer: AudioRenderer) {
        self.geoTagProvider = geoTagProvider
        self.audioRenderer = audioRenderer
    }

    func start() {
        guard tagTask == nil else { return }
        tagTask = Task { [weak self] in
            guard let self else { return }
            for await tag in geoTagProvider.start() {
                await MainActor.run {
                    self.currentTag = tag
                    if self.state == .playing {
                        self.audioRenderer.apply(tag: tag, fade: .default)
                    }
                }
            }
        }
    }

    func stop() {
        tagTask?.cancel()
        tagTask = nil
        playbackTask?.cancel()
        playbackTask = nil
        geoTagProvider.stop()
        audioRenderer.stop()
        state = .idle
    }

    func togglePlayback() {
        switch state {
        case .idle, .paused:
            beginPlayback()
        case .playing:
            pausePlayback()
        case .loading, .error:
            break
        }
    }

    func retryPlayback() {
        beginPlayback()
    }

    private func beginPlayback() {
        guard state != .loading else { return }
        guard currentTag != nil else {
            state = .error(.locationUnavailable)
            return
        }

        state = .loading
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            await MainActor.run {
                guard let self else { return }
                self.audioRenderer.start()
                if let tag = self.currentTag {
                    self.audioRenderer.apply(tag: tag, fade: .default)
                }
                self.state = .playing
            }
        }
    }

    private func pausePlayback() {
        audioRenderer.stop()
        state = .paused
    }
}

#if DEBUG
extension PlaybackStore {
    var debugMockScenarios: [DebugOverlayData.MockScenario] {
        guard geoTagProvider is MockGeoTagProvider else { return [] }
        return GeoTag.allCases.map { tag in
            DebugOverlayData.MockScenario(
                id: tag.rawValue,
                name: tag.rawValue.capitalized,
                summary: "固定タグ: \(tag.rawValue)"
            )
        }
    }

    func selectMockScenario(id: String) {
        guard let tag = GeoTag(rawValue: id),
              let provider = geoTagProvider as? MockGeoTagProvider else { return }
        provider.setFixedTag(tag)
        currentTag = tag
        if state == .playing {
            audioRenderer.apply(tag: tag, fade: .default)
        }
    }
}
#endif
