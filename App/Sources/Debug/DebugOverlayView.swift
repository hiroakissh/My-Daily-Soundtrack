import SwiftUI

#if DEBUG
struct DebugOverlayData {
    struct Context {
        var geoTag: String
        var timeBand: String
        var weather: String
        var motion: String
        var cadence: Int?
    }

    struct Scene {
        var current: String
        var candidate: String?
        var lockRemaining: TimeInterval?
        var confidence: Int?
    }

    struct Playback {
        struct Layer: Identifiable {
            var id: String { name }
            var name: String
            var level: Double
        }

        var status: String
        var preset: String
        var layers: [Layer]
        var volume: Double
    }

    struct MockScenario: Identifiable {
        var id: String
        var name: String
        var summary: String
    }

    var context: Context
    var scene: Scene
    var playback: Playback
    var mockScenarios: [MockScenario]
    var selectedMockID: String?
}

struct DebugOverlayView: View {
    let data: DebugOverlayData
    var onClose: () -> Void = {}
    var onSelectMock: (DebugOverlayData.MockScenario) -> Void = { _ in }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 12) {
                header
                section(title: "Context") {
                    contextRows
                }
                section(title: "Scene") {
                    sceneRows
                }
                section(title: "Playback") {
                    playbackRows
                }
                section(title: "Mock") {
                    mockRows
                }
            }
            .padding(16)
            .frame(maxWidth: 540)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 24, y: 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.easeOut(duration: 0.18), value: data.selectedMockID)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Debug Overlay")
                    .font(.headline)
                Text("PH1 — dev build only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var contextRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow(label: "GeoTag", value: data.context.geoTag)
            infoRow(label: "TimeBand", value: data.context.timeBand)
            infoRow(label: "Weather", value: data.context.weather)
            infoRow(label: "Motion", value: data.context.motion)
            if let cadence = data.context.cadence {
                infoRow(label: "Cadence", value: "\(cadence) spm")
            }
        }
    }

    private var sceneRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            infoRow(label: "Current", value: data.scene.current)
            if let candidate = data.scene.candidate {
                infoRow(label: "Candidate", value: candidate)
            }
            if let lockRemaining = data.scene.lockRemaining {
                infoRow(label: "Lock", value: "\(Int(lockRemaining))s remaining")
            }
            if let confidence = data.scene.confidence {
                infoRow(label: "Confidence", value: "\(confidence)%")
            }
        }
    }

    private var playbackRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoRow(label: "Status", value: data.playback.status)
            infoRow(label: "Preset", value: data.playback.preset)
            infoRow(label: "Volume", value: String(format: "%.0f%%", data.playback.volume * 100))
            VStack(alignment: .leading, spacing: 8) {
                Text("Layers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(data.playback.layers) { layer in
                    layerMeter(name: layer.name, level: layer.level)
                }
            }
        }
    }

    private var mockRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            if data.mockScenarios.isEmpty {
                Text("No mock scenarios connected")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(data.mockScenarios) { scenario in
                    Button {
                        onSelectMock(scenario)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(scenario.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(scenario.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if scenario.id == data.selectedMockID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(scenario.id == data.selectedMockID ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.primary)
        }
    }

    private func layerMeter(name: String, level: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(String(format: "%.0f%%", level * 100))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                let width = proxy.size.width * max(0, min(1, level))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing))
                        .frame(width: width)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Preview

extension DebugOverlayData {
    static var preview: DebugOverlayData {
        DebugOverlayData(
            context: .init(
                geoTag: "urban",
                timeBand: "morning",
                weather: "cloudy",
                motion: "walking",
                cadence: 102
            ),
            scene: .init(
                current: "commute_hurry",
                candidate: "rainy_walk",
                lockRemaining: 24,
                confidence: 82
            ),
            playback: .init(
                status: "rendering",
                preset: "urban_hustle",
                layers: [
                    .init(name: "pad", level: 0.76),
                    .init(name: "arp", level: 0.42),
                    .init(name: "beat", level: 0.68),
                    .init(name: "fx", level: 0.33),
                    .init(name: "fieldNoise", level: 0.54)
                ],
                volume: 0.8
            ),
            mockScenarios: [
                .init(id: "urban-walk", name: "Urban walk", summary: "Station → street, cadence 100"),
                .init(id: "rainy-walk", name: "Rainy walk", summary: "Park + rain + slow walk"),
                .init(id: "cafe-stay", name: "Cafe stay", summary: "Cafe + idle + lock")
            ],
            selectedMockID: "urban-walk"
        )
    }
}

#Preview("Overlay") {
    DebugOverlayView(data: .preview)
        .preferredColorScheme(.dark)
}
#endif
