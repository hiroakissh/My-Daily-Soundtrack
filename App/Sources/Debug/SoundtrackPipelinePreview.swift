import SwiftUI
import StateObservationKit

struct SoundtrackPipelinePreview: View {
    @StateObservation private var store: SoundtrackStore

    init() {
        let contextAggregator = ContextAggregator(
            geoTagProvider: MockGeoTagProvider(mode: .fixed(.park)),
            timeProvider: FixedTimeProvider(band: .morning),
            weatherProvider: StaticWeatherProvider(
                weather: WeatherState(condition: .sunny, temperature: 18, precipitation: 0)
            ),
            motionProvider: StaticMotionProvider(
                motion: MotionState(activity: .walking, speed: 1.2, cadence: 105)
            ),
            pollInterval: 5
        )
        _store = StateObservation(wrappedValue: SoundtrackStore(contextAggregator: contextAggregator))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Soundtrack Pipeline")
                .font(.headline)
            Text("Scene: \(store.scene.current.rawValue)")
            if let bpm = store.scorePlan?.baseBPM {
                Text(String(format: "BPM: %.0f", bpm))
            }
            if let context = store.context {
                Text("GeoTag: \(context.geoTag.rawValue)")
                Text("TimeBand: \(context.timeBand.rawValue)")
                Text("Weather: \(context.weather.condition.rawValue)")
                Text(String(format: "Cadence: %.0f", context.motion.cadence))
            }
            if store.isOpeningActive {
                Text("Opening Active")
                    .foregroundStyle(.orange)
            }
        }
        .padding(24)
        .onAppear {
            store.start()
        }
        .onDisappear {
            store.stop()
        }
    }
}

#Preview {
    SoundtrackPipelinePreview()
}
