import Foundation

final class StubAudioRenderer: AudioRenderer {
    private(set) var isRunning: Bool = false
    private(set) var activeTag: GeoTag?
    private(set) var lastFade: AudioFade?

    func start() {
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    func apply(tag: GeoTag, fade: AudioFade) {
        activeTag = tag
        lastFade = fade
    }
}
