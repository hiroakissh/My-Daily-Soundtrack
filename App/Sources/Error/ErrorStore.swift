import Foundation

enum ErrorKind {
    case location
    case audio
}

struct ErrorInfo: Equatable {
    let kind: ErrorKind
    let title: String
    let message: String
}

enum ErrorState: Equatable {
    case hidden
    case showing(ErrorInfo)
    case retrying(ErrorInfo)

    var info: ErrorInfo? {
        switch self {
        case .hidden: return nil
        case let .showing(info): return info
        case let .retrying(info): return info
        }
    }

    var isVisible: Bool {
        switch self {
        case .hidden: return false
        default: return true
        }
    }
}

final class ErrorStore: ObservableObject {
    @Published private(set) var state: ErrorState = .hidden

    func present(kind: ErrorKind, title: String? = nil, message: String? = nil) {
        let info = ErrorInfo(
            kind: kind,
            title: title ?? defaultTitle(for: kind),
            message: message ?? defaultMessage(for: kind)
        )
        state = .showing(info)
    }

    func beginRetry() {
        guard case let .showing(info) = state else { return }
        state = .retrying(info)
    }

    func resolve() {
        state = .hidden
    }

    private func defaultTitle(for kind: ErrorKind) -> String {
        switch kind {
        case .location: return "現在地を取得できません"
        case .audio: return "再生を開始できません"
        }
    }

    private func defaultMessage(for kind: ErrorKind) -> String {
        switch kind {
        case .location: return "位置情報の取得に失敗しました。設定を確認してからもう一度お試しください。"
        case .audio: return "オーディオ初期化で問題が発生しました。リトライしてください。"
        }
    }
}
