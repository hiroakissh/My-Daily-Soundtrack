import Foundation
import Observation

@MainActor
@Observable
final class SoundtrackStore {
    var context: ContextSnapshot?
    var scene: SceneEvaluation
    var scorePlan: ScorePlan?
    var isOpeningActive: Bool
    var themeSeed: ThemeSeed?

    private let contextAggregator: ContextAggregator
    private let sceneClassifier: SceneClassifier
    private let scorePlanner: ScorePlanner
    private let openingDirector: OpeningDirector

    private var contextTask: Task<Void, Never>?

    init(
        contextAggregator: ContextAggregator,
        sceneClassifier: SceneClassifier = SceneClassifier(),
        scorePlanner: ScorePlanner = ScorePlanner(),
        openingDirector: OpeningDirector = OpeningDirector()
    ) {
        self.contextAggregator = contextAggregator
        self.sceneClassifier = sceneClassifier
        self.scorePlanner = scorePlanner
        self.openingDirector = openingDirector
        self.scene = SceneEvaluation(current: .natureAmbient, candidate: nil, lockRemaining: nil, confidence: nil)
        self.isOpeningActive = false
        self.themeSeed = openingDirector.themeSeed
    }

    func start() {
        guard contextTask == nil else { return }
        contextTask = Task { [weak self] in
            guard let self else { return }
            for await snapshot in contextAggregator.start() {
                let sceneEvaluation = sceneClassifier.update(context: snapshot, now: snapshot.timestamp)
                let plan = scorePlanner.plan(scene: sceneEvaluation.current, context: snapshot, now: snapshot.timestamp)
                openingDirector.beginIfNeeded(now: snapshot.timestamp, context: snapshot)

                self.context = snapshot
                self.scene = sceneEvaluation
                self.scorePlan = plan
                self.isOpeningActive = openingDirector.isOpeningInProgress(now: snapshot.timestamp)
                self.themeSeed = openingDirector.themeSeed
            }
        }
    }

    func stop() {
        contextTask?.cancel()
        contextTask = nil
        contextAggregator.stop()
    }

    func finishOpening() {
        openingDirector.finish()
        isOpeningActive = false
    }
}
