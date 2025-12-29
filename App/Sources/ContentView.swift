import SwiftUI

struct ContentView: View {
    @StateObject private var permissionStore = PermissionStore(
        requestHandler: {
            try? await Task.sleep(for: .milliseconds(250))
            return .granted
        }
    )
    @State private var bypassPermission = false

    var body: some View {
        Group {
            if shouldShowMain {
                MainPlaceholderView()
            } else {
                PermissionGuideView(
                    store: permissionStore,
                    onGranted: { bypassPermission = true },
                    onSkip: { bypassPermission = true }
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: shouldShowMain)
    }

    private var shouldShowMain: Bool {
        bypassPermission || permissionStore.status == .granted
    }
}

#Preview {
    ContentView()
}

private struct MainPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path")
                .font(.system(size: 48, weight: .medium))
            Text("My Daily Soundtrack")
                .font(.title2.bold())
            Text("メイン再生 UI は別タスクで実装予定です。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
