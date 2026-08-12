import SwiftUI

struct ErrorModalView: View {
    @ObservedObject var store: ErrorStore
    var onPrimary: () -> Void = {}
    var onSecondary: () -> Void = {}

    private var info: ErrorInfo? {
        store.state.info
    }

    private var isRetrying: Bool {
        if case .retrying = store.state { return true }
        return false
    }

    var body: some View {
        if let info {
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 16) {
                    icon(for: info.kind)
                    Text(info.title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(info.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    primaryButton
                    secondaryButton
                }
                .padding(24)
                .frame(maxWidth: 340)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.2), value: store.state)
        }
    }

    private func icon(for kind: ErrorKind) -> some View {
        let symbol: String
        switch kind {
        case .location: symbol = "location.slash.fill"
        case .audio: symbol = "waveform.slash"
        }
        return Image(systemName: symbol)
            .font(.system(size: 36, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.95),
                                Color.cyan.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var primaryButton: some View {
        Button(action: onPrimary) {
            HStack(spacing: 8) {
                if isRetrying {
                    ProgressView()
                        .tint(.primary)
                }
                Text(isRetrying ? "再試行中…" : "再試行")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRetrying)
    }

    private var secondaryButton: some View {
        Button(action: onSecondary) {
            Text("閉じる")
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview("Error Modal") {
    let store = ErrorStore()
    store.present(kind: .location)
    return ErrorModalView(store: store)
}
