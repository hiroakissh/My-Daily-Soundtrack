import Foundation

enum TimeBand: String, CaseIterable, Equatable {
    case morning
    case afternoon
    case evening
    case night
}

struct WeatherState: Equatable {
    enum Condition: String, CaseIterable, Equatable {
        case sunny
        case cloudy
        case rainy
    }

    let condition: Condition
    let temperature: Double
    let precipitation: Double
}

struct MotionState: Equatable {
    enum Activity: String, CaseIterable, Equatable {
        case stopped
        case walking
        case running
    }

    let activity: Activity
    let speed: Double
    let cadence: Double
}

enum SceneID: String, CaseIterable, Equatable {
    case morningIntro = "morning_intro"
    case commuteHurry = "commute_hurry"
    case sunnyWalk = "sunny_walk"
    case rainyWalk = "rainy_walk"
    case cafeStay = "cafe_stay"
    case nightWalk = "night_walk"
    case natureAmbient = "nature_ambient"
}

struct ContextSnapshot: Equatable {
    let geoTag: GeoTag
    let timeBand: TimeBand
    let weather: WeatherState
    let motion: MotionState
    let timestamp: Date
}

struct ScorePlan: Equatable {
    enum Layer: String, CaseIterable, Hashable {
        case pad
        case arp
        case beat
        case fx
        case fieldNoise
    }

    let baseBPM: Double
    let tempoFollowRate: Double
    let layerLevels: [Layer: Double]
    let filterCutoff: Double
    let reverbMix: Double

    func level(for layer: Layer) -> Double {
        layerLevels[layer] ?? 0
    }

    static func interpolate(from: ScorePlan, to: ScorePlan, progress: Double) -> ScorePlan {
        let clamped = min(1, max(0, progress))
        var levels: [Layer: Double] = [:]
        for layer in Layer.allCases {
            let start = from.level(for: layer)
            let end = to.level(for: layer)
            levels[layer] = lerp(start, end, clamped)
        }
        return ScorePlan(
            baseBPM: lerp(from.baseBPM, to.baseBPM, clamped),
            tempoFollowRate: lerp(from.tempoFollowRate, to.tempoFollowRate, clamped),
            layerLevels: levels,
            filterCutoff: lerp(from.filterCutoff, to.filterCutoff, clamped),
            reverbMix: lerp(from.reverbMix, to.reverbMix, clamped)
        )
    }

    private static func lerp(_ from: Double, _ to: Double, _ progress: Double) -> Double {
        from + (to - from) * progress
    }
}

enum TemperatureBucket: String, CaseIterable, Equatable {
    case cold
    case mild
    case warm
    case hot

    static func bucket(for temperature: Double) -> TemperatureBucket {
        switch temperature {
        case ..<8:
            return .cold
        case 8..<18:
            return .mild
        case 18..<27:
            return .warm
        default:
            return .hot
        }
    }
}

struct ThemeSeed: Equatable, Codable {
    let timeBand: TimeBand
    let condition: WeatherState.Condition
    let temperatureBucket: TemperatureBucket

    var storageValue: String {
        [timeBand.rawValue, condition.rawValue, temperatureBucket.rawValue].joined(separator: "|")
    }

    init(timeBand: TimeBand, condition: WeatherState.Condition, temperatureBucket: TemperatureBucket) {
        self.timeBand = timeBand
        self.condition = condition
        self.temperatureBucket = temperatureBucket
    }

    init?(storageValue: String) {
        let parts = storageValue.split(separator: "|")
        guard parts.count == 3,
              let timeBand = TimeBand(rawValue: String(parts[0])),
              let condition = WeatherState.Condition(rawValue: String(parts[1])),
              let bucket = TemperatureBucket(rawValue: String(parts[2]))
        else {
            return nil
        }
        self.timeBand = timeBand
        self.condition = condition
        self.temperatureBucket = bucket
    }
}
