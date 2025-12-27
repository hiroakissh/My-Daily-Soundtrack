import SwiftUI
import StateObservationKit

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path")
                .font(.system(size: 48, weight: .medium))
            Text("My Daily Soundtrack")
                .font(.title2.bold())
            Text("サウンドスケープの骨組みだけを含むスターター。")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
