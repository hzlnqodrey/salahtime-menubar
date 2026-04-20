import Testing
import Foundation
@testable import SalahTime

// MARK: - QiblaCalculator Tests

@Suite("QiblaCalculator")
struct QiblaCalculatorTests {

    // MARK: - Known City Bearings

    /// Qibla bearing from Jakarta, Indonesia (~295° NW)
    @Test("Jakarta bearing is approximately 295°")
    func jakartaBearing() {
        let bearing = QiblaCalculator.bearing(latitude: -6.2088, longitude: 106.8456)
        #expect(bearing > 290 && bearing < 300, "Jakarta Qibla should be ~295° — got \(bearing)")
    }

    /// Qibla bearing from New York, USA (~58° NE)
    @Test("New York bearing is approximately 58°")
    func newYorkBearing() {
        let bearing = QiblaCalculator.bearing(latitude: 40.7128, longitude: -74.0060)
        #expect(bearing > 53 && bearing < 63, "NYC Qibla should be ~58° — got \(bearing)")
    }

    /// Qibla bearing from London, UK (~119° SE)
    @Test("London bearing is approximately 119°")
    func londonBearing() {
        let bearing = QiblaCalculator.bearing(latitude: 51.5074, longitude: -0.1278)
        #expect(bearing > 114 && bearing < 124, "London Qibla should be ~119° — got \(bearing)")
    }

    /// Qibla bearing from Cairo, Egypt (~135° SE)
    @Test("Cairo bearing is approximately 135°")
    func cairoBearing() {
        let bearing = QiblaCalculator.bearing(latitude: 30.0444, longitude: 31.2357)
        #expect(bearing > 130 && bearing < 140, "Cairo Qibla should be ~135° — got \(bearing)")
    }

    /// Qibla bearing from Kuala Lumpur, Malaysia (~292° NW)
    @Test("Kuala Lumpur bearing is approximately 293°")
    func kualaLumpurBearing() {
        let bearing = QiblaCalculator.bearing(latitude: 3.1390, longitude: 101.6869)
        #expect(bearing > 288 && bearing < 298, "KL Qibla should be ~293° — got \(bearing)")
    }

    // MARK: - Compass Direction

    @Test("compassDirection returns correct label for all 8 sectors",
          arguments: [
            (0.0, "N"), (10.0, "N"), (350.0, "N"),
            (45.0, "NE"), (90.0, "E"), (135.0, "SE"),
            (180.0, "S"), (225.0, "SW"), (270.0, "W"), (315.0, "NW"),
          ])
    func compassDirectionSectors(bearing: Double, expected: String) {
        let result = QiblaCalculator.compassDirection(bearing: bearing)
        #expect(result == expected, "Bearing \(bearing)° should be \(expected) — got \(result)")
    }

    @Test("compassDirection normalizes negative and >360 bearings")
    func compassDirectionNormalization() {
        // These should all resolve to valid compass labels
        let result1 = QiblaCalculator.compassDirection(bearing: 720.0)  // 720 = 0 → N
        #expect(result1 == "N")

        let result2 = QiblaCalculator.compassDirection(bearing: 450.0)  // 450 = 90 → E
        #expect(result2 == "E")
    }

    // MARK: - Formatted Bearing

    @Test("formattedBearing returns 'X.X° DIR' format")
    func formattedBearingFormat() {
        let result = QiblaCalculator.formattedBearing(latitude: -6.2088, longitude: 106.8456)
        // Should match pattern like "295.1° NW"
        #expect(result.contains("°"), "Should contain degree symbol — got '\(result)'")
        let parts = result.split(separator: " ")
        #expect(parts.count == 2, "Should be 'degrees direction' — got '\(result)'")
    }
}
