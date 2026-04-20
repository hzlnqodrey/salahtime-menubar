import Testing
import Foundation
@testable import SalahTime

// MARK: - Prayer Model Tests

@Suite("Prayer Enum")
struct PrayerEnumTests {

    // MARK: - All Cases

    @Test("Prayer has exactly 6 cases")
    func caseCount() {
        #expect(Prayer.allCases.count == 6)
    }

    @Test("Prayer raw values are sequential 0-5")
    func rawValues() {
        let expected = [0, 1, 2, 3, 4, 5]
        let actual = Prayer.allCases.map(\.rawValue)
        #expect(actual == expected)
    }

    // MARK: - English Names

    @Test("All prayers have non-empty English names")
    func englishNames() {
        for prayer in Prayer.allCases {
            #expect(!prayer.englishName.isEmpty, "\(prayer) should have an English name")
        }
    }

    @Test("English names are correct",
          arguments: [
            (Prayer.fajr, "Fajr"),
            (.sunrise, "Sunrise"),
            (.dhuhr, "Dhuhr"),
            (.asr, "Asr"),
            (.maghrib, "Maghrib"),
            (.isha, "Isha"),
          ])
    func correctEnglishName(prayer: Prayer, expected: String) {
        #expect(prayer.englishName == expected)
    }

    // MARK: - Arabic Names

    @Test("All prayers have non-empty Arabic names")
    func arabicNames() {
        for prayer in Prayer.allCases {
            #expect(!prayer.arabicName.isEmpty, "\(prayer) should have an Arabic name")
        }
    }

    @Test("Arabic names are distinct")
    func arabicNamesDistinct() {
        let names = Prayer.allCases.map(\.arabicName)
        let unique = Set(names)
        #expect(unique.count == 6, "All Arabic names should be unique")
    }

    // MARK: - Icons

    @Test("All prayers have SF Symbol icon names")
    func iconNames() {
        for prayer in Prayer.allCases {
            #expect(!prayer.icon.isEmpty, "\(prayer) should have an icon")
            #expect(prayer.icon.contains("."), "SF Symbol names contain dots — got '\(prayer.icon)'")
        }
    }

    // MARK: - isActualPrayer

    @Test("Only Sunrise is not an actual prayer")
    func isActualPrayer() {
        for prayer in Prayer.allCases {
            if prayer == .sunrise {
                #expect(!prayer.isActualPrayer, "Sunrise should not be an actual prayer")
            } else {
                #expect(prayer.isActualPrayer, "\(prayer.englishName) should be an actual prayer")
            }
        }
    }

    // MARK: - Identifiable

    @Test("Prayer id matches rawValue")
    func identifiable() {
        for prayer in Prayer.allCases {
            #expect(prayer.id == prayer.rawValue)
        }
    }
}

// MARK: - PrayerTime Tests

@Suite("PrayerTime")
struct PrayerTimeTests {

    @Test("formattedTime returns HH:mm format")
    func formattedTimeFormat() {
        let date = Calendar.current.date(
            from: DateComponents(year: 2026, month: 4, day: 20, hour: 5, minute: 23)
        )!
        let pt = PrayerTime(prayer: .fajr, time: date)
        #expect(pt.formattedTime == "05:23")
    }

    @Test("formattedTime handles midnight")
    func formattedTimeMidnight() {
        let date = Calendar.current.date(
            from: DateComponents(year: 2026, month: 4, day: 20, hour: 0, minute: 0)
        )!
        let pt = PrayerTime(prayer: .fajr, time: date)
        #expect(pt.formattedTime == "00:00")
    }

    @Test("formattedTime handles afternoon")
    func formattedTimeAfternoon() {
        let date = Calendar.current.date(
            from: DateComponents(year: 2026, month: 4, day: 20, hour: 15, minute: 30)
        )!
        let pt = PrayerTime(prayer: .asr, time: date)
        #expect(pt.formattedTime == "15:30")
    }

    @Test("PrayerTime defaults: isNext false, isPassed false")
    func defaults() {
        let pt = PrayerTime(prayer: .dhuhr, time: Date())
        #expect(!pt.isNext)
        #expect(!pt.isPassed)
    }

    @Test("PrayerTime has unique id per instance")
    func uniqueIds() {
        let pt1 = PrayerTime(prayer: .fajr, time: Date())
        let pt2 = PrayerTime(prayer: .fajr, time: Date())
        #expect(pt1.id != pt2.id, "Each PrayerTime should have a unique UUID")
    }
}
