import SwiftUI

struct ContentView: View {
    @StateObject private var onboardingStore = OnboardingStore(slides: OnboardingSlide.defaultSlides)
    #if DEBUG
    @State private var showsDebugOverlay = false
    @State private var selectedMockID: String? = DebugOverlayData.preview.selectedMockID
    #endif

    var body: some View {
        ZStack {
            Group {
                if onboardingStore.isCompleted {
                    PermissionGuidePlaceholder()
                } else {
                    OnboardingView(
                        store: onboardingStore,
                        onComplete: {
                            // TODO: Navigate to permission guide once implemented.
                        }
                    )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: onboardingStore.isCompleted)

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

    private func toggleOverlay() {
        showsDebugOverlay.toggle()
    }
    #endif
}

#Preview {
    ContentView()
}
