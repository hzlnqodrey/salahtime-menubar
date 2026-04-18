import Foundation

// MARK: - Aladhan API Client

/// Lightweight client for the Aladhan Prayer Times API (fallback/validation)
/// API docs: https://aladhan.com/prayer-times-api
struct AladhanAPIClient {

    // MARK: - Response Models

    struct APIResponse: Codable {
        let code: Int
        let status: String
        let data: TimingsData
    }

    struct TimingsData: Codable {
        let timings: Timings
    }

    struct Timings: Codable {
        let Fajr: String
        let Sunrise: String
        let Dhuhr: String
        let Asr: String
        let Maghrib: String
        let Isha: String
    }

    // MARK: - Public API

    /// Fetch prayer times from Aladhan API
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - method: Calculation method number (3 = MWL)
    /// - Returns: Array of PrayerTime objects
    static func fetchPrayerTimes(
        latitude: Double,
        longitude: Double,
        method: Int = 3
    ) async throws -> [PrayerTime] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let dateString = dateFormatter.string(from: Date())

        let urlString = "https://api.aladhan.com/v1/timings/\(dateString)"
            + "?latitude=\(latitude)"
            + "&longitude=\(longitude)"
            + "&method=\(method)"

        guard let url = URL(string: urlString) else {
            throw AladhanError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AladhanError.serverError
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        return parseTimes(apiResponse.data.timings)
    }

    // MARK: - Parsing

    private static func parseTimes(_ timings: Timings) -> [PrayerTime] {
        let now = Date()
        let pairs: [(Prayer, String)] = [
            (.fajr, timings.Fajr),
            (.sunrise, timings.Sunrise),
            (.dhuhr, timings.Dhuhr),
            (.asr, timings.Asr),
            (.maghrib, timings.Maghrib),
            (.isha, timings.Isha),
        ]

        var results: [PrayerTime] = []
        var foundNext = false

        for (prayer, timeStr) in pairs {
            guard let date = parseTimeString(timeStr) else { continue }
            var pt = PrayerTime(prayer: prayer, time: date)
            if !foundNext && date > now {
                pt.isNext = true
                foundNext = true
            } else if date <= now {
                pt.isPassed = true
            }
            results.append(pt)
        }

        return results
    }

    /// Parse "HH:mm" or "HH:mm (TZ)" format to today's Date
    private static func parseTimeString(_ string: String) -> Date? {
        // API returns "05:23 (WIB)" format — strip timezone label
        let cleanTime = string.components(separatedBy: " ").first ?? string

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let timeOnly = formatter.date(from: cleanTime) else { return nil }

        // Combine with today's date
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnly)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0

        return calendar.date(from: components)
    }
}

// MARK: - Errors

enum AladhanError: Error, LocalizedError {
    case invalidURL
    case serverError
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid API URL"
        case .serverError: "Server returned an error"
        case .parsingError: "Failed to parse prayer times"
        }
    }
}
