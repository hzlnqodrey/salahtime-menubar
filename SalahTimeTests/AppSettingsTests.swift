import Testing
import Foundation
@testable import SalahTime

// MARK: - AppSettings Tests

@Suite("AppSettings")
struct AppSettingsTests {

    // MARK: - Singleton

    @Test("shared returns the same instance")
    func singletonIdentity() {
        let a = AppSettings.shared
        let b = AppSettings.shared
        #expect(a === b, "AppSettings.shared should return the same instance")
    }

    // MARK: - Default Values

    @Test("Default calculation method is Muslim World League")
    func defaultCalculationMethod() {
        // This tests the initial enum default — actual UserDefaults value may differ
        // if the user has changed it before
        let method = CalculationMethodSetting.muslimWorldLeague
        #expect(method.rawValue == 0)
        #expect(method.displayName == "Muslim World League")
    }

    @Test("Default menubar display mode is icon only")
    func defaultMenuBarMode() {
        let mode = MenuBarDisplayMode.iconOnly
        #expect(mode.rawValue == 0)
        #expect(mode.displayName == "Icon Only")
    }

    // MARK: - Notification Helpers

    @Test("isNotificationEnabled returns true for default prayers")
    func defaultNotificationEnabled() {
        let settings = AppSettings.shared
        #expect(settings.isNotificationEnabled(for: .fajr) == true)
        #expect(settings.isNotificationEnabled(for: .dhuhr) == true)
        #expect(settings.isNotificationEnabled(for: .asr) == true)
        #expect(settings.isNotificationEnabled(for: .maghrib) == true)
        #expect(settings.isNotificationEnabled(for: .isha) == true)
    }

    @Test("isNotificationEnabled returns false for Sunrise by default")
    func sunriseNotificationDisabled() {
        let settings = AppSettings.shared
        #expect(settings.isNotificationEnabled(for: .sunrise) == false)
    }

    @Test("isAdhanEnabled returns true for Fajr and Maghrib by default")
    func defaultAdhanEnabled() {
        let settings = AppSettings.shared
        #expect(settings.isAdhanEnabled(for: .fajr) == true)
        #expect(settings.isAdhanEnabled(for: .maghrib) == true)
    }

    @Test("isAdhanEnabled returns false for other prayers by default")
    func defaultAdhanDisabled() {
        let settings = AppSettings.shared
        #expect(settings.isAdhanEnabled(for: .dhuhr) == false)
        #expect(settings.isAdhanEnabled(for: .asr) == false)
        #expect(settings.isAdhanEnabled(for: .isha) == false)
    }

    // MARK: - Calculation Method Enum

    @Test("All calculation methods have display names")
    func allMethodsHaveNames() {
        for method in CalculationMethodSetting.allCases {
            #expect(!method.displayName.isEmpty, "\(method) should have a display name")
        }
    }

    @Test("All calculation methods have Aladhan API numbers")
    func allMethodsHaveApiNumbers() {
        for method in CalculationMethodSetting.allCases {
            #expect(method.aladhanMethodNumber > 0, "\(method) should have a positive API number")
        }
    }

    @Test("Aladhan API numbers are unique")
    func apiNumbersUnique() {
        let numbers = CalculationMethodSetting.allCases.map(\.aladhanMethodNumber)
        let unique = Set(numbers)
        #expect(unique.count == numbers.count, "API numbers should be unique")
    }

    @Test("There are exactly 10 calculation methods")
    func calculationMethodCount() {
        #expect(CalculationMethodSetting.allCases.count == 10)
    }

    // MARK: - MenuBarDisplayMode Enum

    @Test("There are exactly 3 display modes")
    func displayModeCount() {
        #expect(MenuBarDisplayMode.allCases.count == 3)
    }

    @Test("All display modes have display names")
    func allModesHaveNames() {
        for mode in MenuBarDisplayMode.allCases {
            #expect(!mode.displayName.isEmpty, "\(mode) should have a display name")
        }
    }

    // MARK: - PrayerNotificationSetting

    @Test("Default notification settings cover all 6 prayers")
    func defaultSettingsCoverAllPrayers() {
        let defaults = PrayerNotificationSetting.defaultSettings
        let expectedKeys = ["fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha"]
        for key in expectedKeys {
            #expect(defaults[key] != nil, "Default settings should include '\(key)'")
        }
    }

    @Test("PrayerNotificationSetting is Codable")
    func codableRoundTrip() throws {
        let original = PrayerNotificationSetting(enabled: true, adhanEnabled: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PrayerNotificationSetting.self, from: data)
        #expect(decoded.enabled == original.enabled)
        #expect(decoded.adhanEnabled == original.adhanEnabled)
    }
}
