import SwiftUI

struct ContentView: View {
    @StateObject private var playbackStore = PlaybackStore()
    @StateObject private var geoTagStore = GeoTagStore()
    #if DEBUG
    @State private var showDebugOverlay = false
    #endif

    var body: some View {
        ZStack {
            MainPlaybackView(
                playbackStore: playbackStore,
                geoTagStore: geoTagStore,
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
    }

    private func togglePlay() {
        switch playbackStore.state {
        case .playing:
            playbackStore.pause()
        default:
            playbackStore.start()
        }
    }

    private func retry() {
        playbackStore.start()
    }

    #if DEBUG
    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Overlay")
                .font(.headline)
            Text("GeoTag: \(geoTagStore.currentTag.rawValue)")
            Text("Playback: \(playbackStore.state.label)")
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
