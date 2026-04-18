import Foundation

// MARK: - Hijri Date Calculator

/// Calculates Hijri dates using the built-in Umm Al-Qura calendar
struct HijriDateCalculator {
    private static let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)

    // MARK: - Arabic Month Names

    private static let hijriMonthNames = [
        1: "محرّم",       // Muharram
        2: "صفر",        // Safar
        3: "ربيع الأول",  // Rabi al-Awwal
        4: "ربيع الثاني", // Rabi al-Thani
        5: "جمادى الأولى", // Jumada al-Ula
        6: "جمادى الآخرة", // Jumada al-Thani
        7: "رجب",        // Rajab
        8: "شعبان",      // Sha'ban
        9: "رمضان",      // Ramadan
        10: "شوّال",      // Shawwal
        11: "ذو القعدة",  // Dhul Qa'dah
        12: "ذو الحجة",   // Dhul Hijjah
    ]

    private static let hijriMonthNamesEnglish = [
        1: "Muharram",
        2: "Safar",
        3: "Rabi al-Awwal",
        4: "Rabi al-Thani",
        5: "Jumada al-Ula",
        6: "Jumada al-Thani",
        7: "Rajab",
        8: "Sha'ban",
        9: "Ramadan",
        10: "Shawwal",
        11: "Dhul Qa'dah",
        12: "Dhul Hijjah",
    ]

    // MARK: - Public API

    /// Get formatted Hijri date for today
    /// Returns: "25 Ramadan 1447" format
    static func todayHijri() -> String {
        formatHijri(date: Date())
    }

    /// Get formatted Hijri date for a given date
    static func formatHijri(date: Date) -> String {
        let components = hijriCalendar.dateComponents([.day, .month, .year], from: date)
        guard let day = components.day,
              let month = components.month,
              let year = components.year else {
            return "—"
        }

        let monthName = hijriMonthNamesEnglish[month] ?? "Unknown"
        return "\(day) \(monthName) \(year)"
    }

    /// Get Arabic-formatted Hijri date
    static func todayHijriArabic() -> String {
        formatHijriArabic(date: Date())
    }

    /// Get Arabic-formatted Hijri date for a given date
    static func formatHijriArabic(date: Date) -> String {
        let components = hijriCalendar.dateComponents([.day, .month, .year], from: date)
        guard let day = components.day,
              let month = components.month,
              let year = components.year else {
            return "—"
        }

        let monthName = hijriMonthNames[month] ?? "—"
        return "\(day) \(monthName) \(year) هـ"
    }

    /// Get Gregorian formatted date
    static func todayGregorian() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: Date())
    }

    /// Check if today is a special Islamic day
    static func specialDay() -> String? {
        let components = hijriCalendar.dateComponents([.day, .month], from: Date())
        guard let day = components.day, let month = components.month else { return nil }

        switch (month, day) {
        case (9, _): return "🌙 Ramadan"
        case (10, 1): return "🎉 Eid al-Fitr"
        case (10, 2), (10, 3): return "🎉 Eid al-Fitr"
        case (12, 10): return "🎉 Eid al-Adha"
        case (12, 11), (12, 12), (12, 13): return "🎉 Eid al-Adha"
        case (1, 10): return "Ashura"
        case (3, 12): return "Mawlid an-Nabi ﷺ"
        case (7, 27): return "Isra' Mi'raj"
        default: return nil
        }
    }
}
