import Foundation

final class OpeningDirector: ObservableObject {
    @Published private(set) var state: OpeningState = .idle

    func start(using snapshot: ContextSnapshot) {
        guard case .idle = state else { return }
        state = .preparing
        let seed = makeSeed(from: snapshot)
        Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run {
                self.state = .playing(seed)
            }
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                self.state = .completed(seed)
            }
        }
    }

    private func makeSeed(from snapshot: ContextSnapshot) -> ThemeSeed {
        let hue: Double
        switch snapshot.timeBand {
        case .morning: hue = 0.12
        case .daytime: hue = 0.55
        case .evening: hue = 0.83
        case .night: hue = 0.66
        }

        let saturation: Double = snapshot.weather == .rainy ? 0.5 : 0.7
        let brightness: Double = snapshot.weather == .rainy ? 0.5 : 0.75
        let accent = accentName(for: snapshot)
        return ThemeSeed(hue: hue, saturation: saturation, brightness: brightness, accent: accent)
    }

    private func accentName(for snapshot: ContextSnapshot) -> String {
        if snapshot.geoTag == .forest || snapshot.geoTag == .river || snapshot.geoTag == .park {
            return "nature"
        }
        if snapshot.geoTag == .cafe {
            return "cozy"
        }
        if snapshot.geoTag == .station || snapshot.motion == .running {
            return "rush"
        }
        if snapshot.weather == .rainy {
            return "rain"
        }
        return "urban"
    }
}
