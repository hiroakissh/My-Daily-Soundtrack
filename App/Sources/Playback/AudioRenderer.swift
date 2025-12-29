import Foundation

protocol AudioRendering {
    func start(tag: GeoTag) async throws
    func pause() async
    func stop() async
    func update(tag: GeoTag) async
}

enum AudioRendererError: Error {
    case failed
}

final class StubAudioRenderer: AudioRendering {
    var shouldFailNextStart = false

    func start(tag: GeoTag) async throws {
        try await Task.sleep(for: .milliseconds(300))
        if shouldFailNextStart {
            shouldFailNextStart = false
            throw AudioRendererError.failed
        }
    }

    func pause() async {
        // Simulate quick pause.
        try? await Task.sleep(for: .milliseconds(80))
    }

    func stop() async {
        try? await Task.sleep(for: .milliseconds(100))
    }

    func update(tag: GeoTag) async {
        // Simulate crossfade.
        try? await Task.sleep(for: .milliseconds(120))
    }
}
