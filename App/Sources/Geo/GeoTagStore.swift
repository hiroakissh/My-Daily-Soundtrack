import Foundation

enum GeoTag: String, CaseIterable {
    case station
    case park
    case cafe
    case river
    case forest
    case urban
}

final class GeoTagStore: ObservableObject {
    @Published private(set) var currentTag: GeoTag = .urban

    func cycleNext() {
        guard let index = GeoTag.allCases.firstIndex(of: currentTag) else { return }
        let next = GeoTag.allCases[(index + 1) % GeoTag.allCases.count]
        currentTag = next
    }
}
