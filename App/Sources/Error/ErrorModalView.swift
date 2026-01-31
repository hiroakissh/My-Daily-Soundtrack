import SwiftUI

struct ErrorModalView: View {
    let type: ErrorType
    let isRetrying: Bool
    var onPrimaryAction: () -> Void = {}
    var onSecondaryAction: () -> Void = {}

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                icon
                VStack(spacing: 8) {
                    Text(titleText)
                        .font(.system(size: 20, weight: .semibold))
                    Text(messageText)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                primaryButton
                secondaryButton
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 24, y: 12)
            )
            .padding(.horizontal, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.2), value: isRetrying)
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.12))
                .frame(width: 56, height: 56)
            Image(systemName: iconName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.blue)
        }
    }

    private var primaryButton: some View {
        Button(action: onPrimaryAction) {
            HStack(spacing: 8) {
                if isRetrying {
                    ProgressView()
                }
                Text(primaryTitle)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRetrying)
    }

    private var secondaryButton: some View {
        Button(action: onSecondaryAction) {
            Text(secondaryTitle)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRetrying)
    }

    private var titleText: String {
        switch type {
        case .location:
            return "位置情報が必要です"
        case .audio:
            return "サウンドを再生できません"
        }
    }

    private var messageText: String {
        switch type {
        case .location:
            return "位置情報がないと現在地のサウンドを再生できません。許可を確認してください。"
        case .audio:
            return "オーディオの初期化に失敗しました。再試行してください。"
        }
    }

    private var primaryTitle: String {
        switch type {
        case .location:
            return "権限を許可"
        case .audio:
            return "再試行"
        }
    }

    private var secondaryTitle: String {
        switch type {
        case .location:
            return "設定を開く"
        case .audio:
            return "あとで"
        }
    }

    private var iconName: String {
        switch type {
        case .location:
            return "location.fill"
        case .audio:
            return "waveform"
        }
    }
}

#Preview("Error Modal") {
    ErrorModalView(type: .location, isRetrying: false)
}
