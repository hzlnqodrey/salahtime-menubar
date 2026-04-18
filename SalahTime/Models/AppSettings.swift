import Foundation
import Observation
import ServiceManagement

// MARK: - Menubar Display Mode

/// Controls what the menubar item shows
enum MenuBarDisplayMode: Int, CaseIterable {
    case iconOnly = 0
    case iconAndPrayer
    case iconAndTime

    var displayName: String {
        switch self {
        case .iconOnly: "Icon Only"
        case .iconAndPrayer: "Icon + Next Prayer"
        case .iconAndTime: "Icon + Time"
        }
    }
}

// MARK: - Calculation Method

/// Prayer time calculation methods supported by adhan-swift
enum CalculationMethodSetting: Int, CaseIterable {
    case muslimWorldLeague = 0
    case northAmerica  // ISNA
    case egyptian
    case ummAlQura
    case karachi
    case dubai
    case kuwait
    case qatar
    case singapore
    case kemenag  // Indonesia / JAKIM

    var displayName: String {
        switch self {
        case .muslimWorldLeague: "Muslim World League"
        case .northAmerica: "ISNA (North America)"
        case .egyptian: "Egyptian General Authority"
        case .ummAlQura: "Umm Al-Qura (Makkah)"
        case .karachi: "University of Karachi"
        case .dubai: "Dubai"
        case .kuwait: "Kuwait"
        case .qatar: "Qatar"
        case .singapore: "Singapore"
        case .kemenag: "KEMENAG / JAKIM"
        }
    }

    /// Aladhan API method number for fallback
    var aladhanMethodNumber: Int {
        switch self {
        case .muslimWorldLeague: 3
        case .northAmerica: 2
        case .egyptian: 5
        case .ummAlQura: 4
        case .karachi: 1
        case .dubai: 12
        case .kuwait: 9
        case .qatar: 10
        case .singapore: 11
        case .kemenag: 20
        }
    }
}

// MARK: - Per-Prayer Notification Settings

/// Notification preferences for each prayer
struct PrayerNotificationSetting: Codable {
    var enabled: Bool = true
    var adhanEnabled: Bool = false

    static let defaultSettings: [String: PrayerNotificationSetting] = [
        "fajr": PrayerNotificationSetting(enabled: true, adhanEnabled: true),
        "sunrise": PrayerNotificationSetting(enabled: false, adhanEnabled: false),
        "dhuhr": PrayerNotificationSetting(enabled: true, adhanEnabled: false),
        "asr": PrayerNotificationSetting(enabled: true, adhanEnabled: false),
        "maghrib": PrayerNotificationSetting(enabled: true, adhanEnabled: true),
        "isha": PrayerNotificationSetting(enabled: true, adhanEnabled: false),
    ]
}

// MARK: - App Settings

/// Central settings manager backed by UserDefaults with @Observable tracking
@Observable
class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - Calculation

    var calculationMethod: CalculationMethodSetting = .muslimWorldLeague {
        didSet { defaults.set(calculationMethod.rawValue, forKey: Keys.calculationMethod) }
    }

    // MARK: - Display

    var menuBarDisplayMode: MenuBarDisplayMode = .iconOnly {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: Keys.menuBarDisplayMode) }
    }

    // MARK: - Location

    var useAutoLocation: Bool = true {
        didSet { defaults.set(useAutoLocation, forKey: Keys.useAutoLocation) }
    }

    var manualLatitude: Double = 0.0 {
        didSet { defaults.set(manualLatitude, forKey: Keys.manualLatitude) }
    }

    var manualLongitude: Double = 0.0 {
        didSet { defaults.set(manualLongitude, forKey: Keys.manualLongitude) }
    }

    var manualCityName: String = "" {
        didSet { defaults.set(manualCityName, forKey: Keys.manualCityName) }
    }

    // MARK: - Notifications

    var preReminderMinutes: Int = 15 {
        didSet { defaults.set(preReminderMinutes, forKey: Keys.preReminderMinutes) }
    }

    var prayerNotifications: [String: PrayerNotificationSetting] = PrayerNotificationSetting.defaultSettings {
        didSet {
            if let data = try? JSONEncoder().encode(prayerNotifications) {
                defaults.set(data, forKey: Keys.prayerNotifications)
            }
        }
    }

    // MARK: - Adhan Audio

    var customAdhanBookmarkData: Data? = nil {
        didSet { defaults.set(customAdhanBookmarkData, forKey: Keys.customAdhanBookmark) }
    }

    /// Resolve the custom Adhan file URL from security-scoped bookmark
    var customAdhanURL: URL? {
        guard let data = customAdhanBookmarkData else { return nil }
        var isStale = false
        return try? URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
    }

    // MARK: - General

    var launchAtLogin: Bool = true {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    // MARK: - Init

    private init() {
        loadFromDefaults()
    }

    private func loadFromDefaults() {
        calculationMethod = CalculationMethodSetting(
            rawValue: defaults.integer(forKey: Keys.calculationMethod)
        ) ?? .muslimWorldLeague

        menuBarDisplayMode = MenuBarDisplayMode(
            rawValue: defaults.integer(forKey: Keys.menuBarDisplayMode)
        ) ?? .iconOnly

        useAutoLocation = defaults.object(forKey: Keys.useAutoLocation) as? Bool ?? true
        manualLatitude = defaults.double(forKey: Keys.manualLatitude)
        manualLongitude = defaults.double(forKey: Keys.manualLongitude)
        manualCityName = defaults.string(forKey: Keys.manualCityName) ?? ""

        preReminderMinutes = defaults.object(forKey: Keys.preReminderMinutes) as? Int ?? 15

        if let data = defaults.data(forKey: Keys.prayerNotifications),
           let decoded = try? JSONDecoder().decode([String: PrayerNotificationSetting].self, from: data) {
            prayerNotifications = decoded
        }

        customAdhanBookmarkData = defaults.data(forKey: Keys.customAdhanBookmark)

        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? true
    }

    // MARK: - Helpers

    func isNotificationEnabled(for prayer: Prayer) -> Bool {
        prayerNotifications[prayer.englishName.lowercased()]?.enabled ?? true
    }

    func isAdhanEnabled(for prayer: Prayer) -> Bool {
        prayerNotifications[prayer.englishName.lowercased()]?.adhanEnabled ?? false
    }

    func setNotification(for prayer: Prayer, enabled: Bool) {
        var setting = prayerNotifications[prayer.englishName.lowercased()] ?? PrayerNotificationSetting()
        setting.enabled = enabled
        prayerNotifications[prayer.englishName.lowercased()] = setting
    }

    func setAdhan(for prayer: Prayer, enabled: Bool) {
        var setting = prayerNotifications[prayer.englishName.lowercased()] ?? PrayerNotificationSetting()
        setting.adhanEnabled = enabled
        prayerNotifications[prayer.englishName.lowercased()] = setting
    }

    private func updateLaunchAtLogin() {
        if launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}

// MARK: - UserDefaults Keys

private enum Keys {
    static let calculationMethod = "calculationMethod"
    static let menuBarDisplayMode = "menuBarDisplayMode"
    static let useAutoLocation = "useAutoLocation"
    static let manualLatitude = "manualLatitude"
    static let manualLongitude = "manualLongitude"
    static let manualCityName = "manualCityName"
    static let preReminderMinutes = "preReminderMinutes"
    static let prayerNotifications = "prayerNotifications"
    static let customAdhanBookmark = "customAdhanBookmark"
    static let launchAtLogin = "launchAtLogin"
}
