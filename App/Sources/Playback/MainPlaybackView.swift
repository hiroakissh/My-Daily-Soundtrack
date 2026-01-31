import SwiftUI

struct MainPlaybackView: View {
    @ObservedObject var store: PlaybackStore
    @ObservedObject var errorStore: ErrorStore
    var onRequestPermission: () -> Void = {}
    var onOpenSettings: () -> Void = {}
    var onDismissError: () -> Void = {}

    @State private var isPulsing = false
    @State private var showDebugOverlay = false

    var body: some View {
        ZStack {
            background
            VStack {
                header
                Spacer()
                playbackButton
            }
            .padding(.top, 36)
            .padding(.bottom, 48)
            .padding(.horizontal, 24)

            if let errorType = errorStore.currentError {
                ErrorModalView(
                    type: errorType,
                    isRetrying: errorStore.isRetrying,
                    onPrimaryAction: { handlePrimaryErrorAction(errorType) },
                    onSecondaryAction: { handleSecondaryErrorAction(errorType) }
                )
                .transition(.opacity)
            }

            #if DEBUG
            if showDebugOverlay {
                DebugOverlayView(
                    data: debugData,
                    onClose: { showDebugOverlay = false },
                    onSelectMock: { scenario in
                        store.selectMockScenario(id: scenario.id)
                    }
                )
            }
            #endif
        }
        .onAppear {
            store.start()
        }
        .onDisappear {
            store.stop()
        }
        #if DEBUG
        .simultaneousGesture(TapGesture(count: 3).onEnded {
            showDebugOverlay.toggle()
        })
        #endif
        .onChange(of: store.state) { newValue in
            if case .playing = newValue {
                isPulsing = true
            } else {
                isPulsing = false
            }
        }
        .onChange(of: store.currentTag) { _ in
            if store.state == .playing {
                isPulsing = true
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(store.currentTag?.rawValue.uppercased() ?? "NO TAG")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                playbackIndicator
            }
            Spacer()
        }
    }

    private var playbackIndicator: some View {
        Group {
            switch store.state {
            case .loading:
                ProgressView()
            case .playing:
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.35), lineWidth: 2)
                        .frame(width: 18, height: 18)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isPulsing ? 1.2 : 0.7)
                        .opacity(isPulsing ? 0.9 : 0.6)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
                }
            case .paused, .idle:
                Circle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 10, height: 10)
            case .error:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityLabel(Text(accessibilityIndicatorText))
    }

    private var playbackButton: some View {
        Button(action: store.togglePlayback) {
            Image(systemName: buttonIcon)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(Color.blue, in: Circle())
                .shadow(color: Color.blue.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(store.state == .loading)
    }

    private var buttonIcon: String {
        switch store.state {
        case .playing:
            return "stop.fill"
        default:
            return "play.fill"
        }
    }

    private var accessibilityIndicatorText: String {
        switch store.state {
        case .playing:
            return "再生中"
        case .paused:
            return "一時停止中"
        case .loading:
            return "読み込み中"
        case .error:
            return "エラー"
        case .idle:
            return "停止中"
        }
    }

    private func handlePrimaryErrorAction(_ type: ErrorType) {
        errorStore.startRetry()
        switch type {
        case .location:
            onRequestPermission()
            errorStore.finishRetry(success: true, type: type)
        case .audio:
            store.retryPlayback()
        }
    }

    private func handleSecondaryErrorAction(_ type: ErrorType) {
        switch type {
        case .location:
            onOpenSettings()
        case .audio:
            onDismissError()
        }
    }

    #if DEBUG
    private var debugData: DebugOverlayData {
        DebugOverlayData(
            context: .init(
                geoTag: store.currentTag?.rawValue ?? "unknown",
                timeBand: "—",
                weather: "—",
                motion: "—",
                cadence: nil
            ),
            scene: .init(
                current: "ph1",
                candidate: nil,
                lockRemaining: nil,
                confidence: nil
            ),
            playback: .init(
                status: "\(store.state)",
                preset: store.currentTag?.rawValue ?? "unknown",
                layers: [
                    .init(name: "pad", level: 0.7),
                    .init(name: "fx", level: 0.4),
                    .init(name: "fieldNoise", level: 0.5)
                ],
                volume: 0.8
            ),
            mockScenarios: store.debugMockScenarios,
            selectedMockID: store.currentTag?.rawValue
        )
    }
    #endif
}

#Preview("Main Playback") {
    MainPlaybackView(
        store: PlaybackStore(geoTagProvider: MockGeoTagProvider(mode: .fixed(.urban)), audioRenderer: StubAudioRenderer()),
        errorStore: ErrorStore()
    )
}
