import CoreMotion
import Foundation

final class CoreMotionMotionProvider: MotionProvider {
    private let activityManager: CMMotionActivityManager?
    private let pedometer: CMPedometer?
    private let queue: OperationQueue
    private let lock = NSLock()
    private let fallback: MotionState

    private var lastActivity: MotionState.Activity = .stopped
    private var lastCadence: Double = 0
    private var lastSpeed: Double = 0
    private var latestMotion: MotionState?

    init(
        activityManager: CMMotionActivityManager? = CMMotionActivityManager(),
        pedometer: CMPedometer? = CMPedometer(),
        fallback: MotionState = MotionState(activity: .stopped, speed: 0, cadence: 0)
    ) {
        self.activityManager = activityManager
        self.pedometer = pedometer
        self.fallback = fallback
        self.queue = OperationQueue()
        self.queue.qualityOfService = .utility
        startUpdates()
    }

    func fetchMotion() async -> MotionState? {
        lock.lock()
        defer { lock.unlock() }
        return latestMotion ?? fallback
    }

    private func startUpdates() {
        if CMMotionActivityManager.isActivityAvailable(), let activityManager {
            activityManager.startActivityUpdates(to: queue) { [weak self] activity in
                guard let self, let activity else { return }
                self.updateActivity(activity)
            }
        }

        if CMPedometer.isStepCountingAvailable(), let pedometer {
            pedometer.startUpdates(from: Date()) { [weak self] data, _ in
                guard let self, let data else { return }
                self.updatePedometer(data)
            }
        }
    }

    private func updateActivity(_ activity: CMMotionActivity) {
        let next: MotionState.Activity
        if activity.running {
            next = .running
        } else if activity.walking {
            next = .walking
        } else if activity.stationary {
            next = .stopped
        } else {
            next = .stopped
        }
        updateMotion(activity: next)
    }

    private func updatePedometer(_ data: CMPedometerData) {
        var cadence = lastCadence
        if CMPedometer.isCadenceAvailable(), let value = data.currentCadence?.doubleValue {
            cadence = max(0, value * 60)
        }

        var speed = lastSpeed
        if CMPedometer.isPaceAvailable(), let pace = data.currentPace?.doubleValue, pace > 0 {
            speed = 1.0 / pace
        }

        updateMotion(cadence: cadence, speed: speed)
    }

    private func updateMotion(
        activity: MotionState.Activity? = nil,
        cadence: Double? = nil,
        speed: Double? = nil
    ) {
        lock.lock()
        if let activity {
            lastActivity = activity
        }
        if let cadence {
            lastCadence = cadence
        }
        if let speed {
            lastSpeed = speed
        }
        latestMotion = MotionState(activity: lastActivity, speed: lastSpeed, cadence: lastCadence)
        lock.unlock()
    }

    deinit {
        activityManager?.stopActivityUpdates()
        pedometer?.stopUpdates()
    }
}
