import Foundation

struct ThemeSeed: Equatable {
    var hue: Double
    var saturation: Double
    var brightness: Double
    var accent: String
}

enum OpeningState: Equatable {
    case idle
    case preparing
    case playing(ThemeSeed)
    case completed(ThemeSeed)
}
