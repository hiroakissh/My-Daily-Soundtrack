import Foundation

struct AudioFade: Equatable {
    let duration: TimeInterval

    static let `default` = AudioFade(duration: 1.5)
}

protocol AudioRenderer {
    var isRunning: Bool { get }

    func start()
    func stop()
    func apply(tag: GeoTag, fade: AudioFade)
}
