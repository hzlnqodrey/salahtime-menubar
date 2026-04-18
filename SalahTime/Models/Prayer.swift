import SwiftUI

// MARK: - Prayer Enum

/// Represents the six daily Islamic prayer times
enum Prayer: Int, CaseIterable, Identifiable, Codable {
    case fajr = 0
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: Int { rawValue }

    /// English name of the prayer
    var englishName: String {
        switch self {
        case .fajr: "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }

    /// Arabic name of the prayer
    var arabicName: String {
        switch self {
        case .fajr: "الفجر"
        case .sunrise: "الشروق"
        case .dhuhr: "الظهر"
        case .asr: "العصر"
        case .maghrib: "المغرب"
        case .isha: "العشاء"
        }
    }

    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .fajr: "moon.stars.fill"
        case .sunrise: "sunrise.fill"
        case .dhuhr: "sun.max.fill"
        case .asr: "sun.haze.fill"
        case .maghrib: "sunset.fill"
        case .isha: "moon.fill"
        }
    }

    /// Whether this is an actual prayer (excludes Sunrise)
    var isActualPrayer: Bool {
        self != .sunrise
    }
}

// MARK: - PrayerTime

/// A prayer paired with its calculated time for a given day
struct PrayerTime: Identifiable {
    let id = UUID()
    let prayer: Prayer
    let time: Date
    var isNext: Bool = false
    var isPassed: Bool = false

    /// Formatted time string (e.g., "05:23")
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}
