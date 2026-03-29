import Foundation

/// 動きデータを解析し、強度・テンポ・ピークを算出するロジック
final class MotionAnalyzer {
    // MARK: - Configuration
    private let windowSize: Int = 20
    private let peakThreshold: Double = 0.25
    private let minPeakInterval: TimeInterval = 0.25
    private let maxPeakHistory: Int = 10
    private let maxNormalizedIntensity: Double = 2.5

    // MARK: - State
    private var intensityWindow: [Double] = []
    private var peakTimestamps: [TimeInterval] = []
    private var lastPeakTimestamp: TimeInterval = 0

    // MARK: - Public

    func analyze(_ data: MotionData) -> MotionAnalysisResult {
        let rawIntensity = data.compositeIntensity
        let normalized = min(rawIntensity / maxNormalizedIntensity, 1.0)

        // ローリング平均
        intensityWindow.append(normalized)
        if intensityWindow.count > windowSize {
            intensityWindow.removeFirst()
        }
        let smoothed = intensityWindow.reduce(0, +) / Double(intensityWindow.count)

        // ピーク検出
        let isPeak = detectPeak(
            intensity: normalized,
            timestamp: data.timestamp
        )

        return MotionAnalysisResult(
            intensity: normalized,
            tempo: calculateTempo(),
            isPeak: isPeak,
            smoothedIntensity: smoothed
        )
    }

    func reset() {
        intensityWindow.removeAll()
        peakTimestamps.removeAll()
        lastPeakTimestamp = 0
    }

    // MARK: - Private

    private func detectPeak(intensity: Double, timestamp: TimeInterval) -> Bool {
        guard intensity > peakThreshold,
              timestamp - lastPeakTimestamp > minPeakInterval else {
            return false
        }
        lastPeakTimestamp = timestamp
        peakTimestamps.append(timestamp)
        if peakTimestamps.count > maxPeakHistory {
            peakTimestamps.removeFirst()
        }
        return true
    }

    /// ピーク間隔からBPMを推定
    private func calculateTempo() -> Double {
        guard peakTimestamps.count >= 3 else { return 0 }

        var intervals: [Double] = []
        for i in 1..<peakTimestamps.count {
            let interval = peakTimestamps[i] - peakTimestamps[i - 1]
            if interval > 0 && interval < 3.0 { // 3秒以上の間隔は除外
                intervals.append(interval)
            }
        }
        guard !intervals.isEmpty else { return 0 }

        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        return min(60.0 / avgInterval, 240.0)
    }
}
