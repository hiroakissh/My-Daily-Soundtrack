import SwiftUI

struct ContentView: View {
    @StateObject private var onboardingStore = OnboardingStore(slides: OnboardingSlide.defaultSlides)

    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
