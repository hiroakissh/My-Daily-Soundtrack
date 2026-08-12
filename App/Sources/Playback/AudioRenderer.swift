import AVFoundation
import Foundation

@MainActor
protocol AudioRendering {
    func start(tag: GeoTag, plan: ScorePlan) async throws
    func pause() async
    func stop() async
    func update(tag: GeoTag, plan: ScorePlan) async
}

enum AudioRendererError: Error {
    case failed
}

/// A small procedural renderer used until bundled stems are available.
/// It generates an 8-bar musical loop with a chord progression, bass,
/// arpeggio, drums, and a restrained field texture. ScorePlan controls the
/// arrangement rather than only changing the root note.
@MainActor
final class ProceduralAudioRenderer: AudioRendering {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 1)
    private let reverb = AVAudioUnitReverb()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var isConfigured = false
    private var isPlaying = false
    private var activeTag: GeoTag = .urban
    private var activePlan: ScorePlan = .zero

    func start(tag: GeoTag, plan: ScorePlan) async throws {
        try configureIfNeeded()
        player.stop()
        activeTag = tag
        activePlan = plan
        apply(plan: plan)
        scheduleBuffer(for: tag, plan: plan)

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

    func update(tag: GeoTag, plan: ScorePlan) async {
        guard isConfigured else { return }
        guard tag != activeTag || plan != activePlan else { return }
        activeTag = tag
        activePlan = plan
        apply(plan: plan)
        guard isPlaying else { return }
        player.stop()
        scheduleBuffer(for: tag, plan: plan)
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
        engine.attach(equalizer)
        engine.attach(reverb)
        equalizer.bands[0].filterType = .lowPass
        equalizer.bands[0].bypass = false
        engine.connect(player, to: equalizer, format: format)
        engine.connect(equalizer, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.55
        reverb.loadFactoryPreset(.mediumHall)
        isConfigured = true
    }

    private func apply(plan: ScorePlan) {
        let filterHz = 500 + (max(0, min(1, plan.filter)) * 7_500)
        equalizer.bands[0].frequency = Float(filterHz)
        equalizer.bands[0].bandwidth = 1.0
        equalizer.bands[0].gain = 0
        equalizer.bands[0].bypass = plan.filter >= 0.99
        reverb.wetDryMix = Float(max(0, min(1, plan.reverb)) * 55)
    }

    private func scheduleBuffer(for tag: GeoTag, plan: ScorePlan) {
        let buffer = makeBuffer(for: tag, plan: plan)
        player.scheduleBuffer(buffer, at: nil, options: [.loops])
    }

    private func makeBuffer(for tag: GeoTag, plan: ScorePlan) -> AVAudioPCMBuffer {
        let bpm = max(60, min(180, plan.baseBPM))
        let beatsPerBar = 4.0
        let bars = 8.0
        let beatDuration = 60.0 / bpm
        let duration = bars * beatsPerBar * beatDuration
        let frameCount = AVAudioFrameCount(format.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let rootMidi = rootMIDINote(for: tag)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        let edgeFadeFrames = Int(sampleRate * 0.06)
        let normalizedPlan = normalized(plan)

        guard let channelData = buffer.floatChannelData else { return buffer }
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let beatPosition = time / beatDuration
            let beat = Int(floor(beatPosition))
            let beatPhase = beatPosition - floor(beatPosition)
            let beatSeconds = beatPhase * beatDuration
            let bar = (beat / 4) % 8
            let chordIndex = (bar / 2) % 4
            let chord = chord(for: rootMidi, index: chordIndex)

            let pad = padSound(time: time, chord: chord) * normalizedPlan.padLevel * 0.22
            let bass = bassSound(
                time: time,
                beat: beat,
                beatSeconds: beatSeconds,
                beatDuration: beatDuration,
                chord: chord
            ) * normalizedPlan.beatLevel * 0.42
            let arp = arpeggioSound(
                time: time,
                beatPosition: beatPosition,
                beatDuration: beatDuration,
                chord: chord
            ) * normalizedPlan.arpLevel * 0.28
            let drums = drumSound(
                beat: beat,
                beatPhase: beatPhase,
                beatSeconds: beatSeconds,
                beatDuration: beatDuration,
                beatLevel: normalizedPlan.beatLevel,
                arpLevel: normalizedPlan.arpLevel,
                fxLevel: normalizedPlan.fxLevel
            )
            let field = fieldSound(time: time) * normalizedPlan.fieldNoiseLevel * 0.035
            let loopFade = min(
                1,
                min(
                    Double(frame) / Double(edgeFadeFrames),
                    Double(Int(frameCount) - frame) / Double(edgeFadeFrames)
                )
            )
            let musical = pad + bass + arp + drums + field
            let left = musical * (0.94 + 0.06 * sin(time * 2 * .pi * 0.07))
            let right = musical * (0.94 - 0.06 * sin(time * 2 * .pi * 0.07))

            for channel in 0..<channelCount {
                let value = channel == 0 ? left : right
                channelData[channel][frame] = Float(tanh(value) * loopFade)
            }
        }
        return buffer
    }

    private func normalized(_ plan: ScorePlan) -> ScorePlan {
        ScorePlan(
            padLevel: clamp(plan.padLevel),
            arpLevel: clamp(plan.arpLevel),
            beatLevel: clamp(plan.beatLevel),
            fxLevel: clamp(plan.fxLevel),
            fieldNoiseLevel: clamp(plan.fieldNoiseLevel),
            baseBPM: max(60, min(180, plan.baseBPM)),
            tempoFollowRate: clamp(plan.tempoFollowRate),
            filter: clamp(plan.filter),
            reverb: clamp(plan.reverb)
        )
    }

    private func clamp(_ value: Double) -> Double {
        max(0, min(1, value))
    }

    private func rootMIDINote(for tag: GeoTag) -> Int {
        switch tag {
        case .station: return 50 // D major
        case .park: return 52 // E major
        case .cafe: return 48 // C major
        case .river: return 53 // F major
        case .forest: return 55 // G major
        case .urban: return 45 // A major
        }
    }

    private func chord(for rootMidi: Int, index: Int) -> (root: Double, third: Double, fifth: Double) {
        let intervals: [(Int, Int, Int)] = [
            (0, 4, 7),
            (9, 12, 16),
            (5, 9, 12),
            (7, 11, 14)
        ]
        let selected = intervals[index % intervals.count]
        return (
            frequency(midi: Double(rootMidi + selected.0)),
            frequency(midi: Double(rootMidi + selected.1)),
            frequency(midi: Double(rootMidi + selected.2))
        )
    }

    private func frequency(midi: Double) -> Double {
        440 * pow(2, (midi - 69) / 12)
    }

    private func padSound(time: Double, chord: (root: Double, third: Double, fifth: Double)) -> Double {
        let pulse = 0.82 + 0.18 * sin(time * 2 * .pi * 0.11)
        return (
            sin(time * 2 * .pi * chord.root) * 0.62 +
            sin(time * 2 * .pi * chord.third) * 0.34 +
            sin(time * 2 * .pi * chord.fifth) * 0.24
        ) * pulse
    }

    private func bassSound(
        time: Double,
        beat: Int,
        beatSeconds: Double,
        beatDuration: Double,
        chord: (root: Double, third: Double, fifth: Double)
    ) -> Double {
        guard beat % 2 == 0 else { return 0 }
        let envelope = exp(-beatSeconds * (7.5 / max(0.1, beatDuration)))
        let root = chord.root / 2
        let fifth = chord.fifth / 2
        let note = beat % 4 == 2 ? fifth : root
        return sin(time * 2 * .pi * note) * envelope
    }

    private func arpeggioSound(
        time: Double,
        beatPosition: Double,
        beatDuration: Double,
        chord: (root: Double, third: Double, fifth: Double)
    ) -> Double {
        let step = Int(floor(beatPosition * 2))
        let stepPhase = beatPosition * 2 - floor(beatPosition * 2)
        let note: Double
        switch step % 4 {
        case 0: note = chord.root * 2
        case 1: note = chord.third * 2
        case 2: note = chord.fifth * 2
        default: note = chord.third * 2
        }
        let envelope = exp(-stepPhase * (8.0 / max(0.1, beatDuration)))
        return sin(time * 2 * .pi * note) * envelope
    }

    private func drumSound(
        beat: Int,
        beatPhase: Double,
        beatSeconds: Double,
        beatDuration: Double,
        beatLevel: Double,
        arpLevel: Double,
        fxLevel: Double
    ) -> Double {
        let kickEnabled = beatLevel > 0.05 && (beat % 2 == 0 || beatLevel > 0.75)
        let kickPhase = beatSeconds
        let kickEnvelope = kickEnabled ? exp(-kickPhase * (18 / max(0.1, beatDuration))) : 0
        let kickFrequency = 52 + 38 * exp(-kickPhase * 28)
        let kick = sin(2 * .pi * kickFrequency * kickPhase) * kickEnvelope * beatLevel * 0.78

        let snareEnabled = beat % 4 == 1 || beat % 4 == 3
        let snareEnvelope = snareEnabled ? exp(-beatSeconds * (24 / max(0.1, beatDuration))) : 0
        let snare = (noise(at: beatSeconds + Double(beat) * beatDuration) * 0.55 +
            sin(2 * .pi * 180 * beatSeconds) * 0.25) * snareEnvelope * beatLevel * 0.38

        let eighth = Int(floor((Double(beat) + beatPhase) * 2))
        let hatPhase = (Double(beat) + beatPhase) * 2 - floor((Double(beat) + beatPhase) * 2)
        let hatEnvelope = exp(-hatPhase * 30) * (0.3 + arpLevel * 0.7)
        let hat = noise(at: timeForHat(beat: eighth, beatDuration: beatDuration) + beatSeconds) * hatEnvelope * beatLevel * 0.16
        let shimmer = noise(at: beatSeconds * 1.7 + Double(beat) * 2.3) * hatEnvelope * fxLevel * 0.1
        return kick + snare + hat + shimmer
    }

    private func timeForHat(beat: Int, beatDuration: Double) -> Double {
        Double(beat) * beatDuration / 2
    }

    private func fieldSound(time: Double) -> Double {
        noise(at: time * 0.7) * 0.55 + sin(time * 2 * .pi * 0.42) * 0.45
    }

    private func noise(at time: Double) -> Double {
        (
            sin(time * 173.17 + 0.7) +
            sin(time * 271.91 + 1.9) +
            sin(time * 419.37 + 3.1)
        ) / 3
    }
}

@MainActor
final class StubAudioRenderer: AudioRendering {
    var shouldFailNextStart = false

    func start(tag: GeoTag, plan: ScorePlan) async throws {
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

    func update(tag: GeoTag, plan: ScorePlan) async {
        try? await Task.sleep(for: .milliseconds(120))
    }
}
