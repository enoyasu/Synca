import Foundation
import CoreMotion
import Combine

/// CoreMotionをラップし、センサーデータをPublishするサービス
final class MotionService: ObservableObject {
    // MARK: - Published
    @Published private(set) var currentMotionData: MotionData = .zero
    @Published private(set) var isActive: Bool = false
    @Published private(set) var isAvailable: Bool = false

    // MARK: - Settings
    var sensitivity: Double = 1.0

    // MARK: - Private
    private let motionManager = CMMotionManager()
    private let operationQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.synca.motion"
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInteractive
        return q
    }()

    private let updateInterval: TimeInterval = 1.0 / 30.0 // 30Hz

    // MARK: - Lifecycle

    init() {
        isAvailable = motionManager.isDeviceMotionAvailable
    }

    // MARK: - Public

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }
        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: operationQueue
        ) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            self.handleMotionUpdate(motion)
        }

        DispatchQueue.main.async { self.isActive = true }
    }

    func stop() {
        guard motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
        DispatchQueue.main.async {
            self.isActive = false
            self.currentMotionData = .zero
        }
    }

    // MARK: - Private

    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        let s = sensitivity
        let data = MotionData(
            accelerationX: motion.userAcceleration.x * s,
            accelerationY: motion.userAcceleration.y * s,
            accelerationZ: motion.userAcceleration.z * s,
            rotationX: motion.rotationRate.x * s,
            rotationY: motion.rotationRate.y * s,
            rotationZ: motion.rotationRate.z * s,
            timestamp: motion.timestamp
        )
        DispatchQueue.main.async { self.currentMotionData = data }
    }
}
