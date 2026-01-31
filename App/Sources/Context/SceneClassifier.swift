import Foundation

struct SceneEvaluation: Equatable {
    let current: SceneID
    let candidate: SceneID?
    let lockRemaining: TimeInterval?
    let confidence: Int?
}

final class SceneClassifier {
    private let lockDuration: TimeInterval
    private let contextTimeout: TimeInterval
    private let startDate: Date

    private var currentScene: SceneID
    private var candidateScene: SceneID?
    private var candidateHits: Int = 0
    private var lockUntil: Date?
    private var stoppedSince: Date?
    private var lastContextAt: Date?
    private var lastSnapshot: ContextSnapshot?

    init(
        startDate: Date = Date(),
        lockDuration: TimeInterval = 60,
        contextTimeout: TimeInterval = 30,
        initialScene: SceneID = .natureAmbient
    ) {
        self.startDate = startDate
        self.lockDuration = lockDuration
        self.contextTimeout = contextTimeout
        self.currentScene = initialScene
    }

    func update(context: ContextSnapshot?, now: Date = Date()) -> SceneEvaluation {
        guard let context else {
            return handleMissingContext(now: now)
        }

        lastContextAt = now
        lastSnapshot = context
        updateStopState(for: context, now: now)

        if let lockUntil, now < lockUntil {
            return evaluation(with: currentScene, lockUntil: lockUntil, now: now)
        }

        let evaluated = evaluateScene(context: context, now: now)
        if evaluated == currentScene {
            candidateScene = nil
            candidateHits = 0
            return evaluation(with: currentScene, lockUntil: nil, now: now)
        }

        if candidateScene == evaluated {
            candidateHits += 1
        } else {
            candidateScene = evaluated
            candidateHits = 1
        }

        if candidateHits >= 2 {
            currentScene = evaluated
            candidateScene = nil
            candidateHits = 0
            lockUntil = now.addingTimeInterval(lockDuration)
            return evaluation(with: currentScene, lockUntil: lockUntil, now: now)
        }

        return evaluation(with: currentScene, lockUntil: nil, now: now)
    }

    private func handleMissingContext(now: Date) -> SceneEvaluation {
        if let lastContextAt, now.timeIntervalSince(lastContextAt) < contextTimeout {
            return evaluation(with: currentScene, lockUntil: lockUntil, now: now)
        }

        let fallback = fallbackScene()
        if fallback != currentScene {
            currentScene = fallback
            lockUntil = now.addingTimeInterval(lockDuration)
        }
        return evaluation(with: currentScene, lockUntil: lockUntil, now: now)
    }

    private func updateStopState(for context: ContextSnapshot, now: Date) {
        if context.motion.activity == .stopped {
            if stoppedSince == nil {
                stoppedSince = now
            }
        } else {
            stoppedSince = nil
        }
    }

    private func evaluateScene(context: ContextSnapshot, now: Date) -> SceneID {
        if context.timeBand == .morning {
            let elapsed = now.timeIntervalSince(startDate)
            if (30...60).contains(elapsed) {
                return .morningIntro
            }
        }

        if context.timeBand == .morning,
           context.geoTag == .station || context.motion.cadence > 110 {
            return .commuteHurry
        }

        if context.weather.condition == .rainy,
           context.motion.activity == .walking {
            return .rainyWalk
        }

        if context.geoTag == .cafe,
           context.motion.activity == .stopped,
           let stoppedSince,
           now.timeIntervalSince(stoppedSince) >= 90 {
            return .cafeStay
        }

        if context.timeBand == .night,
           (context.geoTag == .park || context.geoTag == .urban),
           context.motion.activity == .walking,
           context.motion.cadence < 100 {
            return .nightWalk
        }

        if (context.weather.condition == .sunny || context.weather.condition == .cloudy),
           context.motion.activity == .walking {
            return .sunnyWalk
        }

        if context.geoTag == .forest || context.geoTag == .river || context.geoTag == .park {
            return .natureAmbient
        }

        return .natureAmbient
    }

    private func fallbackScene() -> SceneID {
        guard let lastSnapshot else {
            return .natureAmbient
        }
        if lastSnapshot.geoTag == .forest || lastSnapshot.geoTag == .river || lastSnapshot.geoTag == .park {
            return .natureAmbient
        }
        return .sunnyWalk
    }

    private func evaluation(with scene: SceneID, lockUntil: Date?, now: Date) -> SceneEvaluation {
        let lockRemaining: TimeInterval? = lockUntil.map { max(0, $0.timeIntervalSince(now)) }
        let confidence: Int? = candidateScene == nil ? nil : min(100, candidateHits * 50)
        return SceneEvaluation(
            current: scene,
            candidate: candidateScene,
            lockRemaining: lockRemaining,
            confidence: confidence
        )
    }
}
