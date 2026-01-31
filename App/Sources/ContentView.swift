import SwiftUI

struct ContentView: View {
    private let container: AppContainer

    @StateObject private var onboardingStore: OnboardingStore
    @StateObject private var permissionStore: PermissionStore
    @StateObject private var playbackStore: PlaybackStore
    @StateObject private var errorStore: ErrorStore

    @State private var bypassPermission = false

    init(container: AppContainer = .live()) {
        self.container = container
        _onboardingStore = StateObject(wrappedValue: OnboardingStore(slides: .defaultSlides))
        _permissionStore = StateObject(wrappedValue: PermissionStore())
        _playbackStore = StateObject(wrappedValue: PlaybackStore(
            geoTagProvider: container.geoTagProvider,
            audioRenderer: container.audioRenderer
        ))
        _errorStore = StateObject(wrappedValue: ErrorStore())
    }

    var body: some View {
        Group {
            if shouldShowOnboarding {
                OnboardingView(store: onboardingStore, onComplete: {
                    bypassPermission = false
                })
            } else if shouldShowPermission {
                PermissionGuideView(
                    store: permissionStore,
                    onGranted: { bypassPermission = true },
                    onSkip: { bypassPermission = true }
                )
            } else {
                MainPlaybackView(
                    store: playbackStore,
                    errorStore: errorStore,
                    onRequestPermission: { permissionStore.requestPermission() },
                    onOpenSettings: { permissionStore.openSettings() },
                    onDismissError: { errorStore.close() }
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: shouldShowOnboarding)
        .animation(.easeInOut(duration: 0.25), value: shouldShowPermission)
        .onChange(of: permissionStore.status) { newValue in
            if shouldShowMain, newValue == .denied || newValue == .restricted {
                errorStore.present(.location)
            }
            if newValue == .granted {
                errorStore.close()
            }
        }
        .onChange(of: playbackStore.state) { newValue in
            switch newValue {
            case .error(let error):
                let type: ErrorType = (error == .audioFailure) ? .audio : .location
                errorStore.present(type)
            case .playing, .paused, .idle:
                errorStore.close()
            case .loading:
                break
            }
        }
    }

    private var shouldShowOnboarding: Bool {
        !onboardingStore.isCompleted
    }

    private var shouldShowPermission: Bool {
        !shouldShowOnboarding && !shouldShowMain
    }

    private var shouldShowMain: Bool {
        bypassPermission || permissionStore.status == .granted
    }
}

#Preview {
    ContentView(container: .mocked())
}
