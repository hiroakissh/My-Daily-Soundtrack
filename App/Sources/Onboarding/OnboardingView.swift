import SwiftUI

struct OnboardingView: View {
    @ObservedObject var store: OnboardingStore
    var onComplete: () -> Void = {}

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { store.currentIndex ?? 0 },
            set: { store.jumpTo(index: $0) }
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: selectionBinding) {
                ForEach(Array(store.slides.enumerated()), id: \.offset) { index, slide in
                    OnboardingSlideView(slide: slide, isActive: store.currentIndex == index)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.28), value: store.currentIndex)

            Button(action: skip) {
                Text("スキップ")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 16) {
                pageIndicator
                ctaButton
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            store.startIfNeeded()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(store.slides.indices, id: \.self) { index in
                Circle()
                    .fill(index == store.currentIndex ? Color.primary : Color.primary.opacity(0.25))
                    .frame(width: index == store.currentIndex ? 10 : 8, height: index == store.currentIndex ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: store.currentIndex)
            }
        }
        .padding(.vertical, 4)
    }

    private var ctaButton: some View {
        Button(action: primaryAction) {
            Text(store.isOnLastSlide ? "はじめる" : "次へ")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .disabled(store.isCompleted)
    }

    private func primaryAction() {
        if store.isOnLastSlide {
            complete()
        } else {
            store.goNext()
        }
    }

    private func skip() {
        complete()
    }

    private func complete() {
        store.complete()
        onComplete()
    }
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isActive: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)
            hero
                .frame(width: 260, height: 260)
                .accessibilityLabel(Text("サウンドスケープのイメージ"))
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(.system(size: 24, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text(slide.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 32)
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(slide.gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
            VStack(spacing: 12) {
                Image(systemName: slide.heroSymbol)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(.white)
                waveform
            }
            .padding(32)
        }
        .scaleEffect(isActive ? 1.0 : 0.96)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
    }

    private var waveform: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let heights: [CGFloat] = [0.25, 0.6, 0.4, 0.8, 0.5, 0.35, 0.6]
            HStack(alignment: .center, spacing: 6) {
                ForEach(heights.indices, id: \.self) { idx in
                    Capsule()
                        .fill(.white.opacity(0.8))
                        .frame(width: (width - CGFloat(heights.count - 1) * 6) / CGFloat(heights.count), height: heights[idx] * proxy.size.height)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(Double(idx) * 0.08), value: isActive)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
