import Foundation
import Adhan

// MARK: - Qibla Calculator

/// Calculates the Qibla direction using the Adhan library
struct QiblaCalculator {
    /// Kaaba coordinates in Makkah
    static let kaabaLatitude = 21.4225
    static let kaabaLongitude = 39.8262

    /// Calculate Qibla bearing from given coordinates
    /// Uses the Adhan library's built-in Qibla calculation
    /// - Returns: Bearing in degrees clockwise from North (0-360)
    static func bearing(latitude: Double, longitude: Double) -> Double {
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        let qibla = Qibla(coordinates: coordinates)
        return qibla.direction
    }

    /// Get a compass direction label for the bearing
    static func compassDirection(bearing: Double) -> String {
        let normalized = (bearing.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)

        switch normalized {
        case 0..<22.5, 337.5..<360: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return "N"
        }
    }

    /// Format bearing with compass direction
    static func formattedBearing(latitude: Double, longitude: Double) -> String {
        let b = bearing(latitude: latitude, longitude: longitude)
        let dir = compassDirection(bearing: b)
        return String(format: "%.1f° %@", b, dir)
    }
}
