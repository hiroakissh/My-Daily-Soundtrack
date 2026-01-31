import AVFoundation
import Foundation

final class SimpleAudioRenderer: AudioRenderer {
    private struct LayerSpec: Equatable {
        let waveform: Waveform
        let level: Float
    }

    private enum Waveform: Equatable {
        case sine(frequency: Double)
        case noise
    }

    private struct Preset: Equatable {
        let pad: LayerSpec
        let fx: LayerSpec
        let fieldNoise: LayerSpec
    }

    private struct LayerPlayer {
        let spec: LayerSpec
        let player: AVAudioPlayerNode
    }

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)
    private var activeLayers: [LayerPlayer] = []
    private var fadeTask: Task<Void, Never>?
    private var activeTag: GeoTag?

    private(set) var isRunning: Bool = false

    func start() {
        guard !isRunning else { return }
        configureSession()
        do {
            try engine.start()
            isRunning = true
        } catch {
            isRunning = false
        }
    }

    func stop() {
        fadeTask?.cancel()
        fadeTask = nil
        stopLayers(activeLayers)
        activeLayers.removeAll()
        activeTag = nil
        engine.stop()
        isRunning = false
    }

    func apply(tag: GeoTag, fade: AudioFade) {
        guard isRunning else { return }
        guard activeTag != tag else { return }
        let preset = preset(for: tag)
        let newLayers = makeLayers(from: preset)
        let oldLayers = activeLayers
        activeLayers = newLayers
        activeTag = tag
        fadeTask?.cancel()
        fadeTask = Task { [weak self] in
            await self?.crossfade(incoming: newLayers, outgoing: oldLayers, duration: fade.duration)
        }
    }

    private func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }
        #endif
    }

    private func makeLayers(from preset: Preset) -> [LayerPlayer] {
        guard let format else { return [] }
        let specs = [preset.pad, preset.fx, preset.fieldNoise]
        return specs.map { spec in
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            if let buffer = makeBuffer(for: spec, format: format) {
                player.scheduleBuffer(buffer, at: nil, options: .loops)
            }
            player.volume = 0
            player.play()
            return LayerPlayer(spec: spec, player: player)
        }
    }

    private func makeBuffer(for spec: LayerSpec, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        let channelCount = Int(format.channelCount)
        let amplitude: Float = 0.35
        for channel in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                let value: Float
                switch spec.waveform {
                case let .sine(frequency):
                    let theta = 2 * Double.pi * frequency * Double(frame) / sampleRate
                    value = sin(theta).toFloat() * amplitude
                case .noise:
                    value = Float.random(in: -1...1) * amplitude
                }
                channelData[frame] = value
            }
        }
        return buffer
    }

    private func crossfade(incoming: [LayerPlayer], outgoing: [LayerPlayer], duration: TimeInterval) async {
        let stepDuration = 0.05
        let steps = max(1, Int(duration / stepDuration))
        for step in 0...steps {
            if Task.isCancelled { break }
            let progress = Float(step) / Float(steps)
            for layer in incoming {
                layer.player.volume = layer.spec.level * progress
            }
            for layer in outgoing {
                layer.player.volume = layer.spec.level * (1 - progress)
            }
            if step < steps {
                try? await Task.sleep(for: .seconds(stepDuration))
            }
        }
        stopLayers(outgoing)
    }

    private func stopLayers(_ layers: [LayerPlayer]) {
        for layer in layers {
            layer.player.stop()
            engine.detach(layer.player)
        }
    }

    private func preset(for tag: GeoTag) -> Preset {
        switch tag {
        case .station:
            return Preset(
                pad: LayerSpec(waveform: .sine(frequency: 220), level: 0.6),
                fx: LayerSpec(waveform: .sine(frequency: 880), level: 0.25),
                fieldNoise: LayerSpec(waveform: .noise, level: 0.45)
            )
        case .park:
            return Preset(
                pad: LayerSpec(waveform: .sine(frequency: 174), level: 0.65),
                fx: LayerSpec(waveform: .sine(frequency: 620), level: 0.2),
                fieldNoise: LayerSpec(waveform: .noise, level: 0.35)
            )
        case .cafe:
            return Preset(
                pad: LayerSpec(waveform: .sine(frequency: 246), level: 0.55),
                fx: LayerSpec(waveform: .sine(frequency: 740), level: 0.3),
                fieldNoise: LayerSpec(waveform: .noise, level: 0.4)
            )
        case .river:
            return Preset(
                pad: LayerSpec(waveform: .sine(frequency: 196), level: 0.6),
                fx: LayerSpec(waveform: .sine(frequency: 520), level: 0.22),
                fieldNoise: LayerSpec(waveform: .noise, level: 0.5)
            )
        case .forest:
            return Preset(
                pad: LayerSpec(waveform: .sine(frequency: 164), level: 0.68),
                fx: LayerSpec(waveform: .sine(frequency: 460), level: 0.18),
                fieldNoise: LayerSpec(waveform: .noise, level: 0.45)
            )
        case .urban:
            return Preset(
                pad: LayerSpec(waveform: .sine(frequency: 233), level: 0.62),
                fx: LayerSpec(waveform: .sine(frequency: 700), level: 0.28),
                fieldNoise: LayerSpec(waveform: .noise, level: 0.48)
            )
        }
    }
}

private extension Double {
    func toFloat() -> Float {
        Float(self)
    }
}
