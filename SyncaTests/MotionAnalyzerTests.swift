import XCTest
@testable import Synca

final class MotionAnalyzerTests: XCTestCase {
    var analyzer: MotionAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = MotionAnalyzer()
    }

    override func tearDown() {
        analyzer.reset()
        super.tearDown()
    }

    func testZeroMotionReturnsZeroIntensity() {
        let data = MotionData.zero
        let result = analyzer.analyze(data)
        XCTAssertEqual(result.intensity, 0.0, accuracy: 0.001)
    }

    func testHighMotionReturnsHighIntensity() {
        let data = MotionData(
            accelerationX: 2.0, accelerationY: 2.0, accelerationZ: 2.0,
            rotationX: 1.0, rotationY: 1.0, rotationZ: 1.0,
            timestamp: 1.0
        )
        let result = analyzer.analyze(data)
        XCTAssertGreaterThan(result.intensity, 0.5)
    }

    func testIntensityNormalization() {
        let extremeData = MotionData(
            accelerationX: 100.0, accelerationY: 100.0, accelerationZ: 100.0,
            rotationX: 100.0, rotationY: 100.0, rotationZ: 100.0,
            timestamp: 1.0
        )
        let result = analyzer.analyze(extremeData)
        XCTAssertLessThanOrEqual(result.intensity, 1.0)
    }

    func testEmotionStateFromGauge() {
        XCTAssertEqual(EmotionState(gauge: 0), .calm)
        XCTAssertEqual(EmotionState(gauge: 29), .calm)
        XCTAssertEqual(EmotionState(gauge: 30), .excited)
        XCTAssertEqual(EmotionState(gauge: 69), .excited)
        XCTAssertEqual(EmotionState(gauge: 70), .special)
        XCTAssertEqual(EmotionState(gauge: 100), .special)
    }

    func testReset() {
        let data = MotionData(
            accelerationX: 1.0, accelerationY: 1.0, accelerationZ: 1.0,
            rotationX: 0.5, rotationY: 0.5, rotationZ: 0.5,
            timestamp: 1.0
        )
        _ = analyzer.analyze(data)
        analyzer.reset()
        let result = analyzer.analyze(MotionData.zero)
        XCTAssertEqual(result.intensity, 0.0, accuracy: 0.001)
    }
}
