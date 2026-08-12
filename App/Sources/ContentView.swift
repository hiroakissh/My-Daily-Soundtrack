import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastOpeningDate") private var lastOpeningDate = ""

    @StateObject private var onboardingStore = OnboardingStore(slides: OnboardingSlide.defaultSlides)
    @StateObject private var permissionStore = PermissionStore()
    @StateObject private var session: SoundtrackSessionStore
    @StateObject private var playbackStore: PlaybackStore
    @StateObject private var openingDirector = OpeningDirector()
    @StateObject private var errorStore = ErrorStore()
    @State private var skippedPermissionForSession = false

    #if DEBUG
    @State private var showDebugOverlay = false
    #endif

    init() {
        #if os(iOS)
        let provider = CoreLocationGeoTagProvider(fences: [])
        #else
        let provider = MockGeoTagProvider()
        #endif
        let geoTagStore = GeoTagStore(provider: provider)
        #if os(iOS)
        let motionProvider: any MotionProviderType = CoreMotionProvider()
        #else
        let motionProvider: any MotionProviderType = MockMotionProvider()
        #endif
        _session = StateObject(wrappedValue: SoundtrackSessionStore(
            geoTagStore: geoTagStore,
            motionProvider: motionProvider
        ))
        _playbackStore = StateObject(wrappedValue: PlaybackStore(renderer: ProceduralAudioRenderer()))
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(store: onboardingStore) {
                    hasCompletedOnboarding = true
                }
            } else if shouldShowPermissionGuide {
                PermissionGuideView(
                    store: permissionStore,
                    onGranted: { skippedPermissionForSession = false },
                    onSkip: { skippedPermissionForSession = true }
                )
            } else {
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.25), value: shouldShowPermissionGuide)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            permissionStore.refreshStatus()
        }
    }

    private var shouldShowPermissionGuide: Bool {
        !skippedPermissionForSession && permissionStore.status != .granted
    }

    private var mainContent: some View {
        ZStack {
            MainPlaybackView(
                playbackStore: playbackStore,
                geoTagStore: session.geoTagStore,
                errorStore: errorStore,
                sceneLabel: session.sceneLabel,
                onTogglePlay: togglePlay,
                onRetry: retry
            )

            if case let .playing(seed) = openingDirector.state {
                OpeningSceneView(seed: seed)
                    .transition(.opacity)
            }

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
            playbackStore.bindTagPublisher(session.geoTagStore.tagPublisher)
            playbackStore.bindPlanPublisher(session.scorePlanPublisher)
            _ = await session.geoTagStore.start()
            session.start()
            if shouldPlayOpening {
                openingDirector.start(using: session.contextAggregator.snapshot)
            }
        }
        .onDisappear {
            session.stop()
            session.geoTagStore.stop()
        }
        .onChange(of: playbackStore.state) { _, newValue in
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
        .onChange(of: openingDirector.state) { _, newValue in
            guard case .completed = newValue else { return }
            lastOpeningDate = todayKey
        }
    }

    private func togglePlay() {
        switch playbackStore.state {
        case .playing:
            playbackStore.pause()
        case .error:
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

    private var shouldPlayOpening: Bool {
        lastOpeningDate != todayKey
    }

    private var todayKey: String {
        Date.now.formatted(.dateTime.year().month().day())
    }

    #if DEBUG
    private var debugOverlay: some View {
        DebugOverlayView(
            data: DebugOverlayData(
                context: .init(
                    geoTag: session.contextAggregator.snapshot.geoTag.rawValue,
                    timeBand: session.contextAggregator.snapshot.timeBand.rawValue,
                    weather: session.contextAggregator.snapshot.weather.rawValue,
                    motion: session.contextAggregator.snapshot.motion.rawValue,
                    cadence: session.contextAggregator.snapshot.cadence
                ),
                scene: .init(
                    current: session.classification.current?.rawValue ?? "—",
                    candidate: session.classification.candidate?.rawValue,
                    lockRemaining: session.classification.lockRemaining,
                    confidence: nil
                ),
                playback: .init(
                    status: playbackStore.state.label,
                    preset: session.sceneLabel,
                    layers: [
                        .init(name: "pad", level: session.scorePlan.padLevel),
                        .init(name: "arp", level: session.scorePlan.arpLevel),
                        .init(name: "beat", level: session.scorePlan.beatLevel),
                        .init(name: "fx", level: session.scorePlan.fxLevel),
                        .init(name: "fieldNoise", level: session.scorePlan.fieldNoiseLevel)
                    ],
                    volume: 1
                ),
                mockScenarios: [
                    .init(id: "urban", name: "Urban", summary: "都市の標準シナリオ")
                ],
                selectedMockID: nil
            ),
            onClose: {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showDebugOverlay = false
                }
            }
        )
    }
    #endif
}

#Preview {
    ContentView()
}
