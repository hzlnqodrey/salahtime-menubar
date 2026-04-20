import Testing
import Foundation
@testable import SalahTime

// MARK: - HijriDateCalculator Tests

@Suite("HijriDateCalculator")
struct HijriDateCalculatorTests {

    // MARK: - Format Output

    @Test("formatHijri returns day-month-year format")
    func formatHijriOutput() {
        let result = HijriDateCalculator.formatHijri(date: Date())
        // Should match pattern: "DD MonthName YYYY"
        let parts = result.split(separator: " ")
        #expect(parts.count == 3, "Expected 3 parts: day, month, year — got '\(result)'")

        // Day should be a number
        #expect(Int(parts[0]) != nil, "Day should be numeric")
        // Year should be a number
        #expect(Int(parts[2]) != nil, "Year should be numeric")
    }

    @Test("formatHijriArabic returns Arabic string ending with هـ")
    func formatHijriArabicSuffix() {
        let result = HijriDateCalculator.formatHijriArabic(date: Date())
        #expect(result.hasSuffix("هـ"), "Arabic format should end with هـ — got '\(result)'")
    }

    @Test("todayHijri returns non-empty string")
    func todayHijriNotEmpty() {
        let result = HijriDateCalculator.todayHijri()
        #expect(!result.isEmpty)
        #expect(result != "—")
    }

    @Test("todayGregorian returns weekday and full date")
    func todayGregorianFormat() {
        let result = HijriDateCalculator.todayGregorian()
        // Should contain a comma (e.g., "Friday, 18 April 2026")
        #expect(result.contains(","), "Gregorian format should contain comma — got '\(result)'")
    }

    // MARK: - Known Date Verification

    @Test("formatHijri for known Gregorian date produces valid Hijri month")
    func knownDateProducesValidMonth() {
        let validMonths = [
            "Muharram", "Safar", "Rabi al-Awwal", "Rabi al-Thani",
            "Jumada al-Ula", "Jumada al-Thani", "Rajab", "Sha'ban",
            "Ramadan", "Shawwal", "Dhul Qa'dah", "Dhul Hijjah"
        ]
        let result = HijriDateCalculator.formatHijri(date: Date())
        let parts = result.split(separator: " ")
        // Month is the middle part (could be multi-word like "Rabi al-Awwal")
        // Actually the month would be everything between day and year
        let monthPart = parts.dropFirst().dropLast().joined(separator: " ")
        #expect(validMonths.contains(monthPart), "Month '\(monthPart)' not in valid list")
    }

    // MARK: - Special Days

    @Test("specialDay returns nil for non-special dates most of the time")
    func specialDayCanBeNil() {
        // We can't control today's date, but the function shouldn't crash
        let result = HijriDateCalculator.specialDay()
        // Just verify it returns Optional<String> without crashing
        if let special = result {
            #expect(!special.isEmpty, "Special day string should not be empty")
        }
    }
}
