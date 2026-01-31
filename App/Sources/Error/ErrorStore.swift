import Foundation

enum ErrorType: Equatable {
    case location
    case audio
}

enum ErrorState: Equatable {
    case hidden
    case showing(ErrorType)
    case retrying(ErrorType)
}

final class ErrorStore: ObservableObject {
    @Published private(set) var state: ErrorState = .hidden

    var currentError: ErrorType? {
        switch state {
        case .hidden:
            return nil
        case let .showing(type), let .retrying(type):
            return type
        }
    }

    var isRetrying: Bool {
        if case .retrying = state { return true }
        return false
    }

    func present(_ type: ErrorType) {
        state = .showing(type)
    }

    func startRetry() {
        guard case let .showing(type) = state else { return }
        state = .retrying(type)
    }

    func finishRetry(success: Bool, type: ErrorType) {
        state = success ? .hidden : .showing(type)
    }

    func close() {
        state = .hidden
    }
}
