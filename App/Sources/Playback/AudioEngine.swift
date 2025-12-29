import AVFoundation
import Foundation

/// Minimal audio engine scaffold for PH1/PH2 stubs.
final class AudioEngine {
    private let engine = AVAudioEngine()
    private var isRunning = false

    func start() throws {
        guard !isRunning else { return }
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
    }

    func apply(plan: ScorePlan) {
        // Placeholder: wire plan parameters to mixers/filters in future.
        _ = plan
    }
}
