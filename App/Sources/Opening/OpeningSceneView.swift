import SwiftUI

struct OpeningSceneView: View {
    let seed: ThemeSeed

    var body: some View {
        ZStack {
            AngularGradient(
                gradient: Gradient(colors: [baseColor.opacity(0.8), accentColor.opacity(0.6), baseColor.opacity(0.9)]),
                center: .center
            )
            .blur(radius: 24)
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [baseColor, accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                    .shadow(color: accentColor.opacity(0.4), radius: 18, y: 8)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                Text("My Daily Soundtrack")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Opening theme: \(seed.accent)")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding()
        }
    }

    private var baseColor: Color {
        Color(hue: seed.hue, saturation: seed.saturation, brightness: seed.brightness)
    }

    private var accentColor: Color {
        switch seed.accent {
        case "nature": return .green
        case "cozy": return .orange
        case "rush": return .red
        case "rain": return .blue
        default: return .purple
        }
    }
}

#Preview("Opening Scene") {
    OpeningSceneView(
        seed: ThemeSeed(
            hue: 0.55,
            saturation: 0.7,
            brightness: 0.75,
            accent: "urban"
        )
    )
}
