import CoreMotion
import Foundation

#if os(iOS)
final class CoreMotionProvider: MotionProviderType {
    private let activityManager = CMMotionActivityManager()
    private let pedometer = CMPedometer()

    private(set) var currentMotion: MotionState = .idle
    private(set) var cadence: Int?

    func start() {
        if CMMotionActivityManager.isActivityAvailable() {
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity else { return }
                self?.updateMotion(from: activity)
            }
        }

        if CMPedometer.isCadenceAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] data, _ in
                guard let cadence = data?.currentCadence?.doubleValue else { return }
                self?.cadence = Int(cadence * 60) // convert Hz to spm
            }
        }
    }

    func stop() {
        activityManager.stopActivityUpdates()
        pedometer.stopUpdates()
    }

    private func updateMotion(from activity: CMMotionActivity) {
        if activity.running == true {
            currentMotion = .running
        } else if activity.walking == true {
            currentMotion = .walking
        } else {
            currentMotion = .idle
        }
    }
}
#endif
