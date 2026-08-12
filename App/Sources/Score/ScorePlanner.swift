import Foundation

struct SceneScorePreset {
    var scene: SceneID
    var plan: ScorePlan
}

final class ScorePlanner {
    private let presets: [SceneID: ScorePlan]
    private let walkBoost: Double
    private let runBoost: Double

    init(presets: [SceneScorePreset] = SceneScorePreset.defaultPresets, walkBoost: Double = 0.12, runBoost: Double = 0.25) {
        var dict: [SceneID: ScorePlan] = [:]
        presets.forEach { dict[$0.scene] = $0.plan }
        self.presets = dict
        self.walkBoost = walkBoost
        self.runBoost = runBoost
    }

    func plan(scene: SceneID, motion: MotionState, cadence: Int?) -> ScorePlan {
        let base = presets[scene] ?? presets.values.first ?? ScorePlan.zero
        let boost = levelBoost(for: motion, cadence: cadence)
        return ScorePlan(
            padLevel: clamp(base.padLevel + boost.pad),
            arpLevel: clamp(base.arpLevel + boost.arp),
            beatLevel: clamp(base.beatLevel + boost.beat),
            fxLevel: clamp(base.fxLevel),
            fieldNoiseLevel: clamp(base.fieldNoiseLevel),
            baseBPM: base.baseBPM + boost.bpmDelta,
            tempoFollowRate: clamp(base.tempoFollowRate),
            filter: clamp(base.filter),
            reverb: clamp(base.reverb - boost.reverbCut)
        )
    }

    private func levelBoost(for motion: MotionState, cadence: Int?) -> (pad: Double, arp: Double, beat: Double, bpmDelta: Double, reverbCut: Double) {
        switch motion {
        case .idle:
            return (pad: 0.05, arp: -0.05, beat: -0.18, bpmDelta: -4, reverbCut: -0.05)
        case .walking:
            let factor = walkBoost
            return (pad: 0.0, arp: factor * 0.5, beat: factor, bpmDelta: cadenceBoost(cadence), reverbCut: 0.08)
        case .running:
            let factor = runBoost
            return (pad: -0.05, arp: factor * 0.6, beat: factor, bpmDelta: cadenceBoost(cadence) + 6, reverbCut: 0.1)
        }
    }

    private func cadenceBoost(_ cadence: Int?) -> Double {
        guard let cadence else { return 0 }
        let clamped = max(0, min(200, cadence))
        // Scale a normal walking cadence around 100 spm to a bounded 0–6 BPM lift.
        // Slower cadence can gently pull the plan down, while high cadence is clipped.
        let normalized = (Double(clamped) - 100) / 100
        return max(-6, min(6, normalized * 6))
    }

    private func clamp(_ value: Double, min: Double = 0, max: Double = 1) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}

extension SceneScorePreset {
    static var defaultPresets: [SceneScorePreset] {
        [
            .init(scene: .morningIntro, plan: .init(
                padLevel: 0.7, arpLevel: 0.15, beatLevel: 0.1, fxLevel: 0.2, fieldNoiseLevel: 0.3,
                baseBPM: 94, tempoFollowRate: 0.2, filter: 0.55, reverb: 0.55
            )),
            .init(scene: .commuteHurry, plan: .init(
                padLevel: 0.4, arpLevel: 0.7, beatLevel: 0.9, fxLevel: 0.5, fieldNoiseLevel: 0.3,
                baseBPM: 120, tempoFollowRate: 0.6, filter: 0.75, reverb: 0.3
            )),
            .init(scene: .sunnyWalk, plan: .init(
                padLevel: 0.6, arpLevel: 0.5, beatLevel: 0.6, fxLevel: 0.2, fieldNoiseLevel: 0.35,
                baseBPM: 114, tempoFollowRate: 0.5, filter: 0.7, reverb: 0.5
            )),
            .init(scene: .rainyWalk, plan: .init(
                padLevel: 0.7, arpLevel: 0.3, beatLevel: 0.4, fxLevel: 0.6, fieldNoiseLevel: 0.5,
                baseBPM: 102, tempoFollowRate: 0.4, filter: 0.35, reverb: 0.75
            )),
            .init(scene: .cafeStay, plan: .init(
                padLevel: 0.8, arpLevel: 0.2, beatLevel: 0.1, fxLevel: 0.3, fieldNoiseLevel: 0.25,
                baseBPM: 86, tempoFollowRate: 0.2, filter: 0.5, reverb: 0.8
            )),
            .init(scene: .nightWalk, plan: .init(
                padLevel: 0.7, arpLevel: 0.4, beatLevel: 0.5, fxLevel: 0.6, fieldNoiseLevel: 0.3,
                baseBPM: 106, tempoFollowRate: 0.4, filter: 0.45, reverb: 0.65
            )),
            .init(scene: .natureAmbient, plan: .init(
                padLevel: 0.8, arpLevel: 0.15, beatLevel: 0.1, fxLevel: 0.6, fieldNoiseLevel: 0.8,
                baseBPM: 78, tempoFollowRate: 0.2, filter: 0.4, reverb: 0.8
            ))
        ]
    }
}

extension ScorePlan {
    static var zero: ScorePlan {
        ScorePlan(
            padLevel: 0,
            arpLevel: 0,
            beatLevel: 0,
            fxLevel: 0,
            fieldNoiseLevel: 0,
            baseBPM: 90,
            tempoFollowRate: 0.1,
            filter: 0.5,
            reverb: 0.5
        )
    }
}
