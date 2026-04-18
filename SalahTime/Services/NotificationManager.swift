import Foundation
import UserNotifications
import AVFoundation
import Observation

// MARK: - Notification Manager

/// Manages macOS notifications and Adhan audio playback for prayer times
@Observable
class NotificationManager: NSObject {
    var isPermissionGranted: Bool = false
    var isAdhanPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var prayerTimeObserver: Any?
    private var preReminderTimers: [Timer] = []

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        observePrayerTimeArrivals()
    }

    // MARK: - Permission

    /// Request notification permission from the user
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isPermissionGranted = granted
            }
        }
    }

    /// Check current authorization status
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    /// Schedule all prayer notifications and pre-reminders for the day
    func scheduleNotifications(for prayerTimes: [PrayerTime]) {
        guard isPermissionGranted else { return }

        // Clear existing scheduled notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        cancelPreReminderTimers()

        let settings = AppSettings.shared
        let now = Date()

        for pt in prayerTimes {
            guard pt.time > now else { continue }  // Skip past prayers

            let prayerKey = pt.prayer.englishName.lowercased()
            let notifSetting = settings.prayerNotifications[prayerKey]
            guard notifSetting?.enabled == true else { continue }

            // Main prayer notification
            scheduleSingleNotification(
                identifier: "prayer_\(prayerKey)",
                title: "\(pt.prayer.englishName) - \(pt.prayer.arabicName)",
                body: "It's time for \(pt.prayer.englishName) prayer 🕌",
                date: pt.time
            )

            // Schedule Adhan audio (via Timer since AVAudioPlayer needs to play in-app)
            if notifSetting?.adhanEnabled == true {
                scheduleAdhanPlayback(at: pt.time, prayer: pt.prayer)
            }

            // Pre-reminder
            if settings.preReminderMinutes > 0 {
                let preDate = pt.time.addingTimeInterval(-Double(settings.preReminderMinutes) * 60)
                if preDate > now {
                    scheduleSingleNotification(
                        identifier: "pre_\(prayerKey)",
                        title: "\(pt.prayer.englishName) in \(settings.preReminderMinutes) min",
                        body: "Prepare for \(pt.prayer.englishName) prayer ⏰",
                        date: preDate
                    )
                }
            }
        }
    }

    // MARK: - Single Notification

    private func scheduleSingleNotification(
        identifier: String,
        title: String,
        body: String,
        date: Date
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Adhan Audio

    /// Schedule Adhan playback at the prayer time
    private func scheduleAdhanPlayback(at date: Date, prayer: Prayer) {
        let interval = date.timeIntervalSince(Date())
        guard interval > 0 else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.playAdhan()
            }
        }
        preReminderTimers.append(timer)
    }

    /// Play Adhan audio
    func playAdhan() {
        let settings = AppSettings.shared
        let url: URL

        // Check for custom Adhan file
        if let customURL = settings.customAdhanURL {
            _ = customURL.startAccessingSecurityScopedResource()
            url = customURL
        } else {
            // Use bundled default Adhan
            guard let bundleURL = Bundle.main.url(forResource: "default_adhan", withExtension: "m4a")
                  ?? Bundle.main.url(forResource: "default_adhan", withExtension: "mp3") else {
                print("⚠️ No Adhan audio file found in bundle")
                return
            }
            url = bundleURL
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isAdhanPlaying = true
        } catch {
            print("⚠️ Failed to play Adhan: \(error.localizedDescription)")
            isAdhanPlaying = false
        }
    }

    /// Stop Adhan playback
    func stopAdhan() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAdhanPlaying = false

        // Release security-scoped resource if using custom file
        if let customURL = AppSettings.shared.customAdhanURL {
            customURL.stopAccessingSecurityScopedResource()
        }
    }

    // MARK: - Observe Prayer Arrivals

    private func observePrayerTimeArrivals() {
        prayerTimeObserver = NotificationCenter.default.addObserver(
            forName: .prayerTimeArrived,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let prayer = notification.userInfo?["prayer"] as? Prayer else { return }
            let settings = AppSettings.shared
            if settings.isAdhanEnabled(for: prayer) {
                self?.playAdhan()
            }
        }
    }

    // MARK: - Cleanup

    private func cancelPreReminderTimers() {
        preReminderTimers.forEach { $0.invalidate() }
        preReminderTimers.removeAll()
    }

    deinit {
        cancelPreReminderTimers()
        if let observer = prayerTimeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show notifications even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
