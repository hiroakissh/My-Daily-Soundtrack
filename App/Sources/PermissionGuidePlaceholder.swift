import SwiftUI

struct PermissionGuidePlaceholder: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.primary)
            Text("権限ガイドは未実装です")
                .font(.title3.weight(.semibold))
            Text("オンボーディング完了後は、次のタスクで権限ガイドに遷移する予定です。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
