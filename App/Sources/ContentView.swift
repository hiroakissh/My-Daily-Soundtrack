import SwiftUI

struct ContentView: View {
    #if DEBUG
    @State private var showsDebugOverlay = false
    @State private var selectedMockID: String? = DebugOverlayData.preview.selectedMockID
    #endif

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 48, weight: .medium))
                Text("My Daily Soundtrack")
                    .font(.title2.bold())
                Text("サウンドスケープの骨組みだけを含むスターター。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                #if DEBUG
                debugHint
                #endif
            }
            .padding()

            #if DEBUG
            if showsDebugOverlay {
                DebugOverlayView(
                    data: placeholderOverlayData,
                    onClose: toggleOverlay,
                    onSelectMock: { scenario in
                        selectedMockID = scenario.id
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            #endif
        }
        #if DEBUG
        .simultaneousGesture(
            TapGesture(count: 3)
                .onEnded {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        toggleOverlay()
                    }
                }
        )
        #endif
    }

    #if DEBUG
    private var placeholderOverlayData: DebugOverlayData {
        var data = DebugOverlayData.preview
        data.selectedMockID = selectedMockID
        return data
    }

    private var debugHint: some View {
        VStack(spacing: 4) {
            Text("Debug overlay: triple-tap anywhere in this view.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let selectedMockID {
                Text("Active mock: \(selectedMockID)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func toggleOverlay() {
        showsDebugOverlay.toggle()
    }
    #endif
}

#Preview {
    ContentView()
}
