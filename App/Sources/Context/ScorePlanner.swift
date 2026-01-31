import Foundation

final class ScorePlanner {
    private struct SceneProfile {
        let bpmRange: ClosedRange<Double>
        let baseBPM: Double
        let tempoFollowRate: Double
        let layers: [ScorePlan.Layer: Double]
        let filterCutoff: Double
        let reverbMix: Double
    }

    private let profiles: [SceneID: SceneProfile] = [
        .commuteHurry: SceneProfile(
            bpmRange: 120...132,
            baseBPM: 126,
            tempoFollowRate: 0.6,
            layers: [.beat: 0.9, .arp: 0.7, .pad: 0.4, .fx: 0.5, .fieldNoise: 0.3],
            filterCutoff: 0.75,
            reverbMix: 0.25
        ),
        .sunnyWalk: SceneProfile(
            bpmRange: 110...122,
            baseBPM: 116,
            tempoFollowRate: 0.5,
            layers: [.pad: 0.6, .arp: 0.5, .beat: 0.6, .fx: 0.4, .fieldNoise: 0.3],
            filterCutoff: 0.7,
            reverbMix: 0.45
        ),
        .rainyWalk: SceneProfile(
            bpmRange: 96...108,
            baseBPM: 102,
            tempoFollowRate: 0.4,
            layers: [.beat: 0.4, .arp: 0.3, .pad: 0.7, .fx: 0.6, .fieldNoise: 0.4],
            filterCutoff: 0.4,
            reverbMix: 0.7
        ),
        .cafeStay: SceneProfile(
            bpmRange: 80...92,
            baseBPM: 86,
            tempoFollowRate: 0.2,
            layers: [.beat: 0.1, .arp: 0.2, .pad: 0.8, .fx: 0.3, .fieldNoise: 0.2],
            filterCutoff: 0.6,
            reverbMix: 0.65
        ),
        .nightWalk: SceneProfile(
            bpmRange: 100...112,
            baseBPM: 106,
            tempoFollowRate: 0.4,
            layers: [.beat: 0.5, .arp: 0.4, .pad: 0.7, .fx: 0.6, .fieldNoise: 0.3],
            filterCutoff: 0.55,
            reverbMix: 0.55
        ),
        .natureAmbient: SceneProfile(
            bpmRange: 70...86,
            baseBPM: 78,
            tempoFollowRate: 0.2,
            layers: [.beat: 0.1, .arp: 0.1, .pad: 0.8, .fx: 0.6, .fieldNoise: 0.8],
            filterCutoff: 0.45,
            reverbMix: 0.6
        ),
        .morningIntro: SceneProfile(
            bpmRange: 88...100,
            baseBPM: 94,
            tempoFollowRate: 0.3,
            layers: [.pad: 0.7, .arp: 0.35, .beat: 0.3, .fx: 0.4, .fieldNoise: 0.2],
            filterCutoff: 0.65,
            reverbMix: 0.5
        )
    ]

    private let beatFadeDuration: TimeInterval = 3

    private var currentScene: SceneID?
    private var currentPlan: ScorePlan?
    private var previousPlan: ScorePlan?
    private var transitionStartedAt: Date?
    private var transitionDuration: TimeInterval?
    private var sceneStartedAt: Date?

    private var beatFadeStart: Date?
    private var beatFadeFrom: Double?
    private var wasStopped = false

    func plan(scene: SceneID, context: ContextSnapshot, now: Date = Date()) -> ScorePlan {
        guard let profile = profiles[scene] else {
            return currentPlan ?? fallbackPlan()
        }

        if currentScene != scene {
            previousPlan = currentPlan ?? planForProfile(profile, cadence: context.motion.cadence)
            transitionStartedAt = now
            transitionDuration = transitionDurationForScene(profile)
            sceneStartedAt = now
            currentScene = scene
        }

        var target = planForProfile(profile, cadence: context.motion.cadence)
        target = applyMotionAdjustments(plan: target, context: context, now: now)
        target = applyMorningIntroBuild(plan: target, scene: scene, now: now)

        if let previousPlan,
           let transitionStartedAt,
           let transitionDuration,
           now.timeIntervalSince(transitionStartedAt) < transitionDuration {
            let progress = now.timeIntervalSince(transitionStartedAt) / transitionDuration
            let blended = ScorePlan.interpolate(from: previousPlan, to: target, progress: progress)
            currentPlan = blended
            return blended
        }

        currentPlan = target
        return target
    }

    private func planForProfile(_ profile: SceneProfile, cadence: Double) -> ScorePlan {
        let requested = profile.baseBPM + (cadence * profile.tempoFollowRate)
        let bpm = min(profile.bpmRange.upperBound, max(profile.bpmRange.lowerBound, requested))
        return ScorePlan(
            baseBPM: bpm,
            tempoFollowRate: profile.tempoFollowRate,
            layerLevels: profile.layers,
            filterCutoff: profile.filterCutoff,
            reverbMix: profile.reverbMix
        )
    }

    private func applyMotionAdjustments(plan: ScorePlan, context: ContextSnapshot, now: Date) -> ScorePlan {
        var levels = plan.layerLevels
        var reverb = plan.reverbMix

        if context.motion.activity == .running {
            levels[.beat] = min(1, (levels[.beat] ?? 0) + 0.2)
            levels[.arp] = min(1, (levels[.arp] ?? 0) + 0.2)
        }

        if context.motion.activity == .stopped {
            if !wasStopped {
                beatFadeStart = now
                beatFadeFrom = levels[.beat] ?? 0
                wasStopped = true
            }

            let elapsed = now.timeIntervalSince(beatFadeStart ?? now)
            let progress = min(1, max(0, elapsed / beatFadeDuration))
            if let from = beatFadeFrom {
                levels[.beat] = from + (0 - from) * progress
            }
            levels[.pad] = min(1, (levels[.pad] ?? 0) + 0.1)
            reverb = min(1, reverb + 0.1)
        } else {
            wasStopped = false
            beatFadeStart = nil
            beatFadeFrom = nil
        }

        return ScorePlan(
            baseBPM: plan.baseBPM,
            tempoFollowRate: plan.tempoFollowRate,
            layerLevels: levels,
            filterCutoff: plan.filterCutoff,
            reverbMix: reverb
        )
    }

    private func applyMorningIntroBuild(plan: ScorePlan, scene: SceneID, now: Date) -> ScorePlan {
        guard scene == .morningIntro, let sceneStartedAt else { return plan }
        let elapsed = now.timeIntervalSince(sceneStartedAt)
        let progress = min(1, max(0, (elapsed - 30) / 30))
        var levels = plan.layerLevels
        if elapsed < 30 {
            levels[.beat] = 0
            levels[.arp] = 0
        } else {
            levels[.beat] = (levels[.beat] ?? 0) * progress
            levels[.arp] = (levels[.arp] ?? 0) * progress
        }
        return ScorePlan(
            baseBPM: plan.baseBPM,
            tempoFollowRate: plan.tempoFollowRate,
            layerLevels: levels,
            filterCutoff: plan.filterCutoff,
            reverbMix: plan.reverbMix
        )
    }

    private func transitionDurationForScene(_ profile: SceneProfile) -> TimeInterval {
        let beatsPerBar = 4.0
        let bars = 2.0
        let secondsPerBeat = 60.0 / profile.baseBPM
        return beatsPerBar * bars * secondsPerBeat
    }

    private func fallbackPlan() -> ScorePlan {
        ScorePlan(
            baseBPM: 90,
            tempoFollowRate: 0.3,
            layerLevels: [.pad: 0.6, .fx: 0.3, .fieldNoise: 0.4],
            filterCutoff: 0.5,
            reverbMix: 0.4
        )
    }
}
