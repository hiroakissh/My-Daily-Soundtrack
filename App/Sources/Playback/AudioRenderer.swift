import AVFoundation
import Foundation

@MainActor
protocol AudioRendering {
    func start(tag: GeoTag) async throws
    func pause() async
    func stop() async
    func update(tag: GeoTag) async
}

enum AudioRendererError: Error {
    case failed
}

/// A small procedural renderer used until bundled stems are available.
/// It produces a continuous, low-volume harmonic bed and changes its root
/// note when the current GeoTag changes.
@MainActor
final class ProceduralAudioRenderer: AudioRendering {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var isConfigured = false
    private var isPlaying = false

    func start(tag: GeoTag) async throws {
        try configureIfNeeded()
        scheduleBuffer(for: tag)

        if !engine.isRunning {
            try engine.start()
        }
        if !player.isPlaying {
            player.play()
        }
        isPlaying = true
    }

    func pause() async {
        player.pause()
        isPlaying = false
    }

    func stop() async {
        player.stop()
        engine.stop()
        isPlaying = false
    }

    func update(tag: GeoTag) async {
        guard isConfigured, isPlaying else { return }
        player.stop()
        scheduleBuffer(for: tag)
        player.play()
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        #endif

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.65
        isConfigured = true
    }

    private func scheduleBuffer(for tag: GeoTag) {
        let buffer = makeBuffer(for: tag)
        player.scheduleBuffer(buffer, at: nil, options: [.loops])
    }

    private func makeBuffer(for tag: GeoTag) -> AVAudioPCMBuffer {
        let duration: Double = 8
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let rootFrequency = frequency(for: tag)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let fadeFrames = Int(sampleRate * 0.08)

        guard let channelData = buffer.floatChannelData else { return buffer }
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let fadeIn = min(1, Double(frame) / Double(fadeFrames))
            let fadeOut = min(1, Double(Int(frameCount) - frame) / Double(fadeFrames))
            let envelope = min(fadeIn, fadeOut) * (0.55 + 0.45 * sin(time * 2 * .pi * 0.16) * 0.5 + 0.5)
            let fundamental = sin(time * 2 * .pi * rootFrequency)
            let fifth = sin(time * 2 * .pi * rootFrequency * 1.5) * 0.34
            let octave = sin(time * 2 * .pi * rootFrequency * 2) * 0.18
            let sample = Float((fundamental + fifth + octave) * 0.10 * envelope)

            for channel in 0..<channelCount {
                channelData[channel][frame] = sample
            }
        }
        return buffer
    }

    private func frequency(for tag: GeoTag) -> Double {
        switch tag {
        case .station: return 196
        case .park: return 220
        case .cafe: return 247
        case .river: return 262
        case .forest: return 294
        case .urban: return 175
        }
    }
}

@MainActor
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
        try? await Task.sleep(for: .milliseconds(80))
    }

    func stop() async {
        try? await Task.sleep(for: .milliseconds(100))
    }

    func update(tag: GeoTag) async {
        try? await Task.sleep(for: .milliseconds(120))
    }
}
