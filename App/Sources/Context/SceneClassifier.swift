import Foundation

final class SceneClassifier {
    private let lockDuration: TimeInterval
    private var lastConfirmed: SceneID?
    private var lastConfirmedAt: Date?
    private var lastCandidate: SceneID?
    private var candidateHits: Int = 0

    init(lockDuration: TimeInterval = 60) {
        self.lockDuration = lockDuration
    }

    func classify(snapshot: ContextSnapshot, now: Date = Date()) -> SceneClassification {
        let proposed = proposeScene(from: snapshot)

        // Keep locked scene if within lock duration.
        if let lastConfirmed, let lastConfirmedAt,
           now.timeIntervalSince(lastConfirmedAt) < lockDuration {
            let remaining = lockDuration - now.timeIntervalSince(lastConfirmedAt)
            // Allow same scene to renew lock if it reappears.
            if proposed == lastConfirmed {
                lastConfirmedAt = now
            }
            return SceneClassification(current: lastConfirmed, candidate: proposed, lockRemaining: remaining)
        }

        // Double-hit confirmation logic.
        if lastCandidate == proposed {
            candidateHits += 1
        } else {
            lastCandidate = proposed
            candidateHits = 1
        }

        if candidateHits >= 2 {
            lastConfirmed = proposed
            lastConfirmedAt = now
            candidateHits = 0
            return SceneClassification(current: proposed, candidate: nil, lockRemaining: lockDuration)
        } else {
            return SceneClassification(current: lastConfirmed, candidate: proposed, lockRemaining: nil)
        }
    }

    private func proposeScene(from snapshot: ContextSnapshot) -> SceneID {
        // Rule order per spec.
        if snapshot.timeBand == .morning {
            return .morningIntro
        }

        if snapshot.timeBand == .morning &&
            (snapshot.geoTag == .station || (snapshot.cadence ?? 0) > 110) {
            return .commuteHurry
        }

        if snapshot.weather == .rainy && snapshot.motion == .walking {
            return .rainyWalk
        }

        if snapshot.geoTag == .cafe && (snapshot.motion == .idle || (snapshot.cadence ?? 0) == 0) {
            return .cafeStay
        }

        if snapshot.timeBand == .night &&
            (snapshot.geoTag == .park || snapshot.geoTag == .urban) &&
            snapshot.motion == .walking &&
            (snapshot.cadence ?? 0) < 100 {
            return .nightWalk
        }

        if (snapshot.weather == .clear || snapshot.weather == .cloudy) && snapshot.motion == .walking {
            return .sunnyWalk
        }

        if snapshot.geoTag == .forest || snapshot.geoTag == .river || snapshot.geoTag == .park || snapshot.motion == .idle {
            return .natureAmbient
        }

        return .natureAmbient
    }
}
