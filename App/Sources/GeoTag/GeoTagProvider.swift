import Foundation

protocol GeoTagProvider {
    var currentTag: GeoTag? { get }

    func start() -> AsyncStream<GeoTag>
    func stop()
}
