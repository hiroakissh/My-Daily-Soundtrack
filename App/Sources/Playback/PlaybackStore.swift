import Combine
import Foundation

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case error(String)

    var label: String {
        switch self {
        case .idle: return "idle"
        case .loading: return "loading"
        case .playing: return "playing"
        case .paused: return "paused"
        case .error: return "error"
        }
    }
}

@MainActor
final class PlaybackStore: ObservableObject {
    @Published private(set) var state: PlaybackState = .idle

    private let renderer: any AudioRendering
    private var currentTag: GeoTag
    private var currentPlan: ScorePlan
    private var cancellables = Set<AnyCancellable>()

    init(
        renderer: some AudioRendering,
        initialTag: GeoTag = .urban,
        initialPlan: ScorePlan = .zero,
        tagPublisher: AnyPublisher<GeoTag, Never>? = nil
    ) {
        self.renderer = renderer
        self.currentTag = initialTag
        self.currentPlan = initialPlan
        if let tagPublisher {
            bindTagPublisher(tagPublisher)
        }
    }

    func bindTagPublisher(_ publisher: AnyPublisher<GeoTag, Never>) {
        cancellables.removeAll()
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tag in
                guard let self else { return }
                self.currentTag = tag
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.renderer.update(tag: tag, plan: self.currentPlan)
                }
            }
            .store(in: &cancellables)
    }

    func bindPlanPublisher(_ publisher: AnyPublisher<ScorePlan, Never>) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plan in
                guard let self else { return }
                self.currentPlan = plan
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.renderer.update(tag: self.currentTag, plan: plan)
                }
            }
            .store(in: &cancellables)
    }

    func setPlan(_ plan: ScorePlan) {
        currentPlan = plan
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.renderer.update(tag: self.currentTag, plan: plan)
        }
    }

    func start() {
        guard state != .loading else { return }
        state = .loading
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await renderer.start(tag: currentTag, plan: currentPlan)
                self.state = .playing
            } catch {
                self.state = .error("オーディオの初期化に失敗しました")
            }
        }
    }

    func pause() {
        guard state == .playing else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await renderer.pause()
            self.state = .paused
        }
    }

    func stop() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await renderer.stop()
            self.state = .idle
        }
    }

    func fail(message: String) {
        state = .error(message)
    }
}
