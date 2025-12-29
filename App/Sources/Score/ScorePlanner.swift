import Foundation

struct SceneScorePreset {
    var scene: SceneID
    var plan: ScorePlan
}

final class ScorePlanner {
    private let presets: [SceneID: ScorePlan]
    private let walkBoost: Double
    private let runBoost: Double

    init(presets: [SceneScorePreset], walkBoost: Double = 0.12, runBoost: Double = 0.25) {
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
        // Scale 90–170 spm to ±6 BPM delta.
        let normalized = (Double(clamped) - 130) / 40
        return max(-6, min(6, normalized * 6))
    }

    private func clamp(_ value: Double, min: Double = 0, max: Double = 1) -> Double {
        Swift.min(max, Swift.max(min, value))
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
