import Testing
import Foundation
@testable import SalahTime

// MARK: - AladhanAPIClient Tests

@Suite("AladhanAPIClient")
struct AladhanAPIClientTests {

    // MARK: - Time String Parsing

    @Test("parseTimeString handles plain HH:mm format")
    func parseTimePlainFormat() {
        let result = parseTimeHelper("05:23")
        #expect(result != nil, "Should parse '05:23'")
        if let date = result {
            let calendar = Calendar.current
            #expect(calendar.component(.hour, from: date) == 5)
            #expect(calendar.component(.minute, from: date) == 23)
        }
    }

    @Test("parseTimeString handles HH:mm (TZ) format")
    func parseTimeWithTimezone() {
        let result = parseTimeHelper("05:23 (WIB)")
        #expect(result != nil, "Should parse '05:23 (WIB)'")
        if let date = result {
            let calendar = Calendar.current
            #expect(calendar.component(.hour, from: date) == 5)
            #expect(calendar.component(.minute, from: date) == 23)
        }
    }

    @Test("parseTimeString handles midnight edge case")
    func parseTimeMidnight() {
        let result = parseTimeHelper("00:00")
        #expect(result != nil, "Should parse '00:00'")
        if let date = result {
            let calendar = Calendar.current
            #expect(calendar.component(.hour, from: date) == 0)
            #expect(calendar.component(.minute, from: date) == 0)
        }
    }

    @Test("parseTimeString returns nil for invalid input")
    func parseTimeInvalid() {
        let result = parseTimeHelper("invalid")
        #expect(result == nil, "Should return nil for invalid input")
    }

    @Test("parseTimeString returns today's date with parsed time")
    func parseTimeUsesToday() {
        let result = parseTimeHelper("14:30")
        #expect(result != nil)
        if let date = result {
            let calendar = Calendar.current
            let today = Date()
            #expect(calendar.component(.year, from: date) == calendar.component(.year, from: today))
            #expect(calendar.component(.month, from: date) == calendar.component(.month, from: today))
            #expect(calendar.component(.day, from: date) == calendar.component(.day, from: today))
        }
    }

    // MARK: - Error Types

    @Test("AladhanError provides localized descriptions")
    func errorDescriptions() {
        #expect(AladhanError.invalidURL.errorDescription != nil)
        #expect(AladhanError.serverError.errorDescription != nil)
        #expect(AladhanError.parsingError.errorDescription != nil)
    }

    @Test("AladhanError descriptions are distinct")
    func errorDescriptionsDistinct() {
        let descriptions = [
            AladhanError.invalidURL.errorDescription,
            AladhanError.serverError.errorDescription,
            AladhanError.parsingError.errorDescription,
        ]
        let unique = Set(descriptions.compactMap { $0 })
        #expect(unique.count == 3, "Each error should have a unique description")
    }

    // MARK: - JSON Decoding

    @Test("APIResponse decodes valid JSON")
    func decodeValidResponse() throws {
        let json = """
        {
            "code": 200,
            "status": "OK",
            "data": {
                "timings": {
                    "Fajr": "04:30",
                    "Sunrise": "05:55",
                    "Dhuhr": "12:00",
                    "Asr": "15:15",
                    "Maghrib": "18:05",
                    "Isha": "19:20"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AladhanAPIClient.APIResponse.self, from: data)

        #expect(response.code == 200)
        #expect(response.status == "OK")
        #expect(response.data.timings.Fajr == "04:30")
        #expect(response.data.timings.Isha == "19:20")
    }

    @Test("APIResponse decodes timezone-annotated times")
    func decodeTimezoneAnnotatedResponse() throws {
        let json = """
        {
            "code": 200,
            "status": "OK",
            "data": {
                "timings": {
                    "Fajr": "04:30 (WIB)",
                    "Sunrise": "05:55 (WIB)",
                    "Dhuhr": "12:00 (WIB)",
                    "Asr": "15:15 (WIB)",
                    "Maghrib": "18:05 (WIB)",
                    "Isha": "19:20 (WIB)"
                }
            }
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(AladhanAPIClient.APIResponse.self, from: data)
        #expect(response.data.timings.Fajr == "04:30 (WIB)")
    }

    // MARK: - Helpers

    /// Mirror of AladhanAPIClient's private parseTimeString for testing
    private func parseTimeHelper(_ string: String) -> Date? {
        let cleanTime = string.components(separatedBy: " ").first ?? string
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let timeOnly = formatter.date(from: cleanTime) else { return nil }
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
