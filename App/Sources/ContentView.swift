import SwiftUI

struct ContentView: View {
    @StateObject private var geoTagStore: GeoTagStore = {
        let provider = MockGeoTagProvider()
        let store = GeoTagStore(provider: provider)
        return store
    }()
    @StateObject private var playbackStore = PlaybackStore(
        renderer: StubAudioRenderer()
    )
    @StateObject private var errorStore = ErrorStore()
    #if DEBUG
    @State private var showDebugOverlay = false
    #endif

    var body: some View {
        ZStack {
            MainPlaybackView(
                playbackStore: playbackStore,
                geoTagStore: geoTagStore,
                errorStore: errorStore,
                onTogglePlay: togglePlay,
                onRetry: retry
            )
            #if DEBUG
            if showDebugOverlay {
                debugOverlay
                    .transition(.opacity)
            }
            #endif
        }
        #if DEBUG
        .simultaneousGesture(
            TapGesture(count: 3)
                .onEnded {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showDebugOverlay.toggle()
                    }
                }
        )
        #endif
        .task {
            playbackStore.bindTagPublisher(geoTagStore.tagPublisher)
            _ = await geoTagStore.start()
        }
        .onChange(of: playbackStore.state) { newValue in
            switch newValue {
            case .error(let message):
                errorStore.present(kind: .audio, message: message)
            case .playing:
                if errorStore.state.isVisible {
                    errorStore.resolve()
                }
            default:
                break
            }
        }
    }

    private func togglePlay() {
        switch playbackStore.state {
        case .playing:
            playbackStore.pause()
        case .error:
            errorStore.present(kind: .audio)
            retry()
        default:
            playbackStore.start()
        }
    }

    private func retry() {
        playbackStore.start()
        if errorStore.state.isVisible {
            errorStore.resolve()
        }
    }

    #if DEBUG
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Overlay")
                .font(.headline)
            Text("GeoTag: \(geoTagStore.currentTag.rawValue)")
            Text("Playback: \(playbackStore.state.label)")
            Button("Simulate Error") {
                playbackStore.fail(message: "サンプルエラー")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding()
    }
    #endif
}

#Preview {
    ContentView()
}
