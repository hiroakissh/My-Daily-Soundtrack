import SwiftUI

struct PermissionGuideView: View {
    @ObservedObject var store: PermissionStore
    var onGranted: () -> Void = {}
    var onSkip: () -> Void = {}

    private var isRequesting: Bool {
        store.status == .requesting
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            hero
            copy
            primaryButton
            secondaryButtons
            note
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onChange(of: store.status) { newValue in
            if newValue == .granted {
                onGranted()
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onSkip) {
                Text("あとで")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.9), .purple.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            VStack(spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.white)
                Text("位置と音のつながり")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    private var copy: some View {
        VStack(spacing: 12) {
            Text("位置情報の許可をお願いします")
                .font(.system(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("場所に合わせてサウンドスケープを変えるため、位置情報とバックグラウンド更新を利用します。")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var primaryButton: some View {
        Button(action: requestPermission) {
            HStack(spacing: 8) {
                if isRequesting {
                    ProgressView()
                        .tint(.primary)
                }
                Text(buttonTitle)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRequesting || store.status == .granted)
    }

    private var secondaryButtons: some View {
        VStack(spacing: 12) {
            if store.status == .denied || store.status == .restricted {
                Button(action: store.openSettings) {
                    Text("設定を開く")
                        .font(.callout.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var note: some View {
        VStack(spacing: 8) {
            switch store.status {
            case .denied, .restricted:
                Text("許可がないと正しく音を再生できません。設定アプリで位置情報を許可してください。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            default:
                Text("バックグラウンドオーディオと位置更新を利用します。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 12)
    }

    private var buttonTitle: String {
        switch store.status {
        case .awaitingConsent, .denied, .restricted:
            return "位置情報を許可"
        case .requesting:
            return "確認中…"
        case .granted:
            return "許可済み"
        }
    }

    private func requestPermission() {
        store.requestPermission()
    }
}

// MARK: - Preview

#Preview("Permission Guide") {
    PermissionGuideView(store: PermissionStore())
}
