import Foundation

@MainActor
final class OpeningDirector {
    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let dayKey = "opening.lastDay"
    private let seedKey = "opening.themeSeed"

    private(set) var themeSeed: ThemeSeed?
    private(set) var isOpeningActive = false
    private(set) var openingStartedAt: Date?
    private(set) var openingDuration: TimeInterval = 45

    init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        if let storedSeed = userDefaults.string(forKey: seedKey),
           let themeSeed = ThemeSeed(storageValue: storedSeed) {
            self.themeSeed = themeSeed
        }
    }

    func beginIfNeeded(now: Date = Date(), context: ContextSnapshot) -> Bool {
        let dayString = dayIdentifier(for: now)
        let storedDay = userDefaults.string(forKey: dayKey)

        if isOpeningInProgress(now: now) {
            return true
        }

        if storedDay == dayString, let themeSeed {
            self.themeSeed = themeSeed
            isOpeningActive = false
            return false
        }

        let seed = ThemeSeed(
            timeBand: context.timeBand,
            condition: context.weather.condition,
            temperatureBucket: TemperatureBucket.bucket(for: context.weather.temperature)
        )
        themeSeed = seed
        userDefaults.set(seed.storageValue, forKey: seedKey)
        userDefaults.set(dayString, forKey: dayKey)
        openingStartedAt = now
        openingDuration = 45
        isOpeningActive = true
        return true
    }

    func finish() {
        isOpeningActive = false
        openingStartedAt = nil
    }

    func skip() {
        finish()
    }

    func isOpeningInProgress(now: Date = Date()) -> Bool {
        guard isOpeningActive, let openingStartedAt else { return false }
        if now.timeIntervalSince(openingStartedAt) <= openingDuration {
            return true
        }
        isOpeningActive = false
        return false
    }

    private func dayIdentifier(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
