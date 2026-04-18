import Foundation
import Adhan
import Observation

// MARK: - Prayer Time Manager

/// Central manager for prayer time calculation, countdown, and scheduling
/// Uses adhan-swift for local calculation with Aladhan API as fallback
@Observable
class PrayerTimeManager {
    // MARK: - Published State

    var allPrayerTimes: [PrayerTime] = []
    var nextPrayer: PrayerTime?
    var previousPrayer: PrayerTime?
    var countdownString: String = "--:--:--"
    var countdownSeconds: TimeInterval = 0
    var progress: Double = 0  // 0.0 to 1.0 — progress through current prayer window
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Private

    private var timer: Timer?
    private var midnightTimer: Timer?
    private var lastCalculationDate: Date?

    // MARK: - Calculation

    /// Calculate prayer times for the given coordinates
    func calculatePrayerTimes(latitude: Double, longitude: Double) {
        guard latitude != 0 || longitude != 0 else { return }

        isLoading = true
        errorMessage = nil

        // Primary: Local calculation via adhan-swift
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        let params = calculationParameters()

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: Date())

        if let prayers = PrayerTimes(
            coordinates: coordinates,
            date: dateComponents,
            calculationParameters: params
        ) {
            let now = Date()
            var times: [PrayerTime] = [
                PrayerTime(prayer: .fajr, time: prayers.fajr),
                PrayerTime(prayer: .sunrise, time: prayers.sunrise),
                PrayerTime(prayer: .dhuhr, time: prayers.dhuhr),
                PrayerTime(prayer: .asr, time: prayers.asr),
                PrayerTime(prayer: .maghrib, time: prayers.maghrib),
                PrayerTime(prayer: .isha, time: prayers.isha),
            ]

            // Mark next and passed prayers
            var foundNext = false
            for i in 0..<times.count {
                if !foundNext && times[i].time > now {
                    times[i].isNext = true
                    foundNext = true
                } else if times[i].time <= now {
                    times[i].isPassed = true
                }
            }

            self.allPrayerTimes = times
            self.nextPrayer = times.first(where: { $0.isNext })
            self.previousPrayer = times.last(where: { $0.isPassed })
            self.lastCalculationDate = Date()
            self.isLoading = false

            startCountdown()
            scheduleMidnightRecalculation()
        } else {
            // Fallback: Aladhan API
            fetchFromAPI(latitude: latitude, longitude: longitude)
        }
    }

    /// Fetch from Aladhan API as fallback
    private func fetchFromAPI(latitude: Double, longitude: Double) {
        let method = AppSettings.shared.calculationMethod.aladhanMethodNumber

        Task { @MainActor in
            do {
                let times = try await AladhanAPIClient.fetchPrayerTimes(
                    latitude: latitude,
                    longitude: longitude,
                    method: method
                )
                self.allPrayerTimes = times
                self.nextPrayer = times.first(where: { $0.isNext })
                self.previousPrayer = times.last(where: { $0.isPassed })
                self.lastCalculationDate = Date()
                self.isLoading = false
                self.startCountdown()
                self.scheduleMidnightRecalculation()
            } catch {
                self.errorMessage = "Failed to fetch prayer times: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Countdown Timer

    private func startCountdown() {
        timer?.invalidate()
        updateCountdown()  // Immediate update

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateCountdown()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func updateCountdown() {
        guard let next = nextPrayer else {
            countdownString = "--:--:--"
            countdownSeconds = 0
            progress = 0
            return
        }

        let remaining = next.time.timeIntervalSince(Date())

        if remaining <= 0 {
            // Prayer time arrived — trigger notification and recalculate
            onPrayerTimeArrived(next)
            return
        }

        countdownSeconds = remaining
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        countdownString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)

        // Calculate progress through current prayer window
        if let prev = previousPrayer {
            let totalWindow = next.time.timeIntervalSince(prev.time)
            let elapsed = Date().timeIntervalSince(prev.time)
            progress = min(max(elapsed / totalWindow, 0), 1)
        } else {
            progress = 0
        }
    }

    /// Called when a prayer time arrives
    private func onPrayerTimeArrived(_ prayer: PrayerTime) {
        // Post notification for NotificationManager to handle
        NotificationCenter.default.post(
            name: .prayerTimeArrived,
            object: nil,
            userInfo: ["prayer": prayer.prayer]
        )

        // Recalculate to advance to next prayer
        let settings = AppSettings.shared
        let locationManager = LocationManager()  // Will be injected properly at app level
        calculatePrayerTimes(
            latitude: locationManager.effectiveLatitude,
            longitude: locationManager.effectiveLongitude
        )
    }

    // MARK: - Midnight Recalculation

    private func scheduleMidnightRecalculation() {
        midnightTimer?.invalidate()

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
              let midnight = calendar.date(
                from: calendar.dateComponents([.year, .month, .day], from: tomorrow)
              ) else { return }

        let interval = midnight.timeIntervalSince(Date())
        midnightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                // Re-trigger calculation at midnight
                NotificationCenter.default.post(name: .midnightRecalculation, object: nil)
            }
        }
    }

    // MARK: - Cleanup

    func stop() {
        timer?.invalidate()
        midnightTimer?.invalidate()
        timer = nil
        midnightTimer = nil
    }

    deinit {
        stop()
    }

    // MARK: - Calculation Parameters

    private func calculationParameters() -> CalculationParameters {
        let method = AppSettings.shared.calculationMethod

        switch method {
        case .muslimWorldLeague:
            return CalculationMethod.muslimWorldLeague.params
        case .northAmerica:
            return CalculationMethod.northAmerica.params
        case .egyptian:
            return CalculationMethod.egyptian.params
        case .ummAlQura:
            return CalculationMethod.ummAlQura.params
        case .karachi:
            return CalculationMethod.karachi.params
        case .dubai:
            return CalculationMethod.dubai.params
        case .kuwait:
            return CalculationMethod.kuwait.params
        case .qatar:
            return CalculationMethod.qatar.params
        case .singapore:
            return CalculationMethod.singapore.params
        case .kemenag:
            // KEMENAG / JAKIM: Fajr 20°, Isha 18°
            var params = CalculationMethod.other.params
            params.fajrAngle = 20
            params.ishaAngle = 18
            return params
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let prayerTimeArrived = Notification.Name("prayerTimeArrived")
    static let midnightRecalculation = Notification.Name("midnightRecalculation")
}
