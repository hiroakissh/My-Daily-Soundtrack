import SwiftUI

struct MainPlaybackView: View {
    @ObservedObject var playbackStore: PlaybackStore
    @ObservedObject var geoTagStore: GeoTagStore
    @ObservedObject var errorStore: ErrorStore
    var onTogglePlay: () -> Void = {}
    var onRetry: () -> Void = {}

    private var isLoading: Bool {
        playbackStore.state == .loading
    }

    private var isPlaying: Bool {
        playbackStore.state == .playing
    }

    private var hasError: Bool {
        if case .error = playbackStore.state { return true }
        return false
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 24) {
                header
                Spacer()
                playbackIndicator
                Spacer()
                controlArea
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 36)
            if errorStore.state.isVisible {
                ErrorModalView(
                    store: errorStore,
                    onPrimary: {
                        errorStore.beginRetry()
                        onRetry()
                    },
                    onSecondary: {
                        errorStore.resolve()
                    }
                )
                .transition(.opacity)
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.8),
                Color.purple.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Now Playing")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(geoTagStore.currentTag.rawValue)
                    .font(.system(size: 28, weight: .bold))
                    .textCase(.lowercase)
            }
            Spacer()
            Button {
                geoTagStore.cycleNext()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(10)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel("GeoTag を切り替え")
        }
        .foregroundStyle(.white)
    }

    private var playbackIndicator: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 180, height: 180)
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.4)
                } else {
                    Circle()
                        .fill(Color.white.opacity(isPlaying ? 0.3 : 0.12))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPlaying ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPlaying)
                    Image(systemName: isPlaying ? "waveform" : "pause.circle")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(0.9)
                }
            }
            statusLabel
        }
    }

    private var statusLabel: some View {
        VStack(spacing: 6) {
            Text(statusText)
                .font(.headline)
                .foregroundStyle(.white)
            if hasError {
                Text("現在地を取得できませんでした。リトライしてください。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Text("場所に合わせてサウンドを変化させています。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var controlArea: some View {
        VStack(spacing: 16) {
            Button(action: onTogglePlay) {
                Image(systemName: playButtonSymbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 72, height: 72)
                    .background(.white, in: Circle())
            }
            .buttonStyle(.plain)
            .scaleEffect(isLoading ? 0.96 : 1.0)
            .opacity(isLoading ? 0.6 : 1.0)
            .disabled(isLoading)
            if hasError {
                Button(action: onRetry) {
                    Text("リトライ")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var playButtonSymbol: String {
        switch playbackStore.state {
        case .playing: return "pause.fill"
        default: return "play.fill"
        }
    }

    private var statusText: String {
        switch playbackStore.state {
        case .idle: return "準備完了"
        case .loading: return "読み込み中…"
        case .playing: return "再生中"
        case .paused: return "一時停止中"
        case .error: return "エラー"
        }
    }
}

#Preview("Main Playback") {
    MainPlaybackView(
        playbackStore: PlaybackStore(renderer: StubAudioRenderer()),
        geoTagStore: GeoTagStore(),
        errorStore: ErrorStore(),
        onTogglePlay: {},
        onRetry: {}
    )
}
