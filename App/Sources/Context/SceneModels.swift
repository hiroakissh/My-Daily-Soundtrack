import Foundation

enum SceneID: String, CaseIterable {
    case morningIntro = "morning_intro"
    case commuteHurry = "commute_hurry"
    case rainyWalk = "rainy_walk"
    case cafeStay = "cafe_stay"
    case nightWalk = "night_walk"
    case sunnyWalk = "sunny_walk"
    case natureAmbient = "nature_ambient"
}

struct SceneClassification: Equatable {
    var current: SceneID?
    var candidate: SceneID?
    var lockRemaining: TimeInterval?
}
