import Foundation
import SwiftUI

enum OnboardingState: Equatable {
    case idle
    case showing(index: Int)
    case completed
}

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let heroSymbol: String
    let gradient: LinearGradient
}

final class OnboardingStore: ObservableObject {
    @Published private(set) var state: OnboardingState = .idle
    let slides: [OnboardingSlide]

    init(slides: [OnboardingSlide]) {
        self.slides = slides
    }

    var currentIndex: Int? {
        guard case let .showing(index) = state else { return nil }
        return index
    }

    var isOnLastSlide: Bool {
        guard let index = currentIndex else { return false }
        return index == slides.indices.last
    }

    var isCompleted: Bool {
        if case .completed = state { return true }
        return false
    }

    func startIfNeeded() {
        if case .idle = state {
            state = .showing(index: 0)
        }
    }

    func jumpTo(index: Int) {
        guard slides.indices.contains(index) else { return }
        state = .showing(index: index)
    }

    func goNext() {
        guard let index = currentIndex else { return }
        let next = index + 1
        if slides.indices.contains(next) {
            state = .showing(index: next)
        } else {
            complete()
        }
    }

    func skip() {
        complete()
    }

    func complete() {
        state = .completed
    }
}

extension OnboardingSlide {
    static var defaultSlides: [OnboardingSlide] {
        [
            OnboardingSlide(
                title: "あなたの場所に寄り添う音を届けます",
                subtitle: "街・公園・カフェなど、いまいる場所に合わせて音が変わります。",
                heroSymbol: "location.circle.fill",
                gradient: LinearGradient(
                    colors: [.blue.opacity(0.85), .purple.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            OnboardingSlide(
                title: "移動に合わせてなめらかに変化",
                subtitle: "歩く・立ち止まるなどの動きにあわせてトーンを調整します。",
                heroSymbol: "figure.walk.motion",
                gradient: LinearGradient(
                    colors: [.mint.opacity(0.8), .blue.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            ),
            OnboardingSlide(
                title: "はじめる前に位置情報の許可が必要です",
                subtitle: "位置情報を使ってサウンドを最適化します。次の画面で許可をお願いすることがあります。",
                heroSymbol: "location.viewfinder",
                gradient: LinearGradient(
                    colors: [.orange.opacity(0.9), .pink.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        ]
    }
}
