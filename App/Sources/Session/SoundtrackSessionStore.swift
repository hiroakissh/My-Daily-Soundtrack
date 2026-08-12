import Combine
import Foundation

@MainActor
final class SoundtrackSessionStore: ObservableObject {
    let geoTagStore: GeoTagStore
    let contextAggregator: ContextAggregator

    @Published private(set) var classification: SceneClassification
    @Published private(set) var scorePlan: ScorePlan = .zero
    @Published private(set) var isRunning = false

    private let motionProvider: any MotionProviderType
    private let classifier: SceneClassifier
    private let planner: ScorePlanner
    private var cancellables = Set<AnyCancellable>()

    init(
        geoTagStore: GeoTagStore,
        motionProvider: any MotionProviderType,
        weatherProvider: WeatherProviderType = MockWeatherProvider(),
        classifier: SceneClassifier = SceneClassifier(),
        planner: ScorePlanner = ScorePlanner()
    ) {
        self.geoTagStore = geoTagStore
        self.motionProvider = motionProvider
        self.classifier = classifier
        self.planner = planner
        self.contextAggregator = ContextAggregator(
            geoProvider: geoTagStore,
            weatherProvider: weatherProvider,
            motionProvider: motionProvider
        )
        self.classification = SceneClassification(current: nil, candidate: .natureAmbient, lockRemaining: nil)

        contextAggregator.$snapshot
            .sink { [weak self] snapshot in
                self?.consume(snapshot)
            }
            .store(in: &cancellables)
    }

    var sceneLabel: String {
        (classification.current ?? classification.candidate ?? .natureAmbient).rawValue
    }

    var scorePlanPublisher: AnyPublisher<ScorePlan, Never> {
        $scorePlan.eraseToAnyPublisher()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        motionProvider.start()
        contextAggregator.start()
        consume(contextAggregator.snapshot)
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        contextAggregator.stop()
        motionProvider.stop()
    }

    private func consume(_ snapshot: ContextSnapshot) {
        let result = classifier.classify(snapshot: snapshot, now: snapshot.timestamp)
        classification = result
        scorePlan = planner.plan(
            scene: result.current ?? result.candidate ?? .natureAmbient,
            motion: snapshot.motion,
            cadence: snapshot.cadence
        )
    }
}
