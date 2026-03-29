import Foundation

/// CoreMotionから取得したセンサーデータ
struct MotionData: Equatable {
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
    let rotationX: Double
    let rotationY: Double
    let rotationZ: Double
    let timestamp: TimeInterval

    // MARK: - Computed Properties

    /// 加速度ベクトルの大きさ
    var accelerationMagnitude: Double {
        sqrt(
            accelerationX * accelerationX +
            accelerationY * accelerationY +
            accelerationZ * accelerationZ
        )
    }

    /// 角速度ベクトルの大きさ
    var rotationMagnitude: Double {
        sqrt(
            rotationX * rotationX +
            rotationY * rotationY +
            rotationZ * rotationZ
        )
    }

    /// 複合強度（加速度70% + 回転30%）
    var compositeIntensity: Double {
        accelerationMagnitude * 0.7 + rotationMagnitude * 0.3
    }

    static let zero = MotionData(
        accelerationX: 0, accelerationY: 0, accelerationZ: 0,
        rotationX: 0, rotationY: 0, rotationZ: 0,
        timestamp: 0
    )
}

/// 動き解析結果
struct MotionAnalysisResult {
    let intensity: Double   // 0.0〜1.0 正規化済み強度
    let tempo: Double       // BPM近似値
    let isPeak: Bool        // ピーク検出フラグ
    let smoothedIntensity: Double // 平滑化済み強度
}
