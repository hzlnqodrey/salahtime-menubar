//
//  LocationManager.swift
//  SalahTime
//
//  Created by Hazlan Muhammad Qodri on 21/04/26.
//

import Foundation
import CoreLocation
import Observation

// MARK: - Location Manager

/// Manages device location via CoreLocation with auto-detect and manual override support
@Observable
class LocationManager: NSObject {
    var currentLatitude: Double = 0.0
    var currentLongitude: Double = 0.0
    var cityName: String = "Locating..."
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: String?

    private let clManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var hasReceivedLocation = false
    private var retryCount = 0

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyKilometer
        clManager.distanceFilter = 1000
    }

    // MARK: - Public API

    /// Request location permission and start updating
    func requestLocation() {
        print("📍 [Location] Requesting authorization...")
        print("📍 [Location] Services enabled: \(CLLocationManager.locationServicesEnabled())")
        print("📍 [Location] Current status: \(authorizationStatus.rawValue)")

        guard CLLocationManager.locationServicesEnabled() else {
            locationError = "Location Services disabled. Enable in System Settings → Privacy → Location Services."
            cityName = "Location Disabled"
            print("📍 [Location] ❌ Location Services are disabled system-wide")
            return
        }

        // On macOS, request authorization then start
        clManager.requestWhenInUseAuthorization()

        // Also try starting directly — on macOS this can trigger the permission prompt
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startUpdating()
        }

        // Timeout fallback — if no location after 15 seconds, show manual instructions
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            guard let self = self, !self.hasReceivedLocation else { return }
            if self.currentLatitude == 0.0 && self.currentLongitude == 0.0 {
                print("📍 [Location] ⏰ Timeout — no location received after 15s")
                self.cityName = "Set Location in Settings"
                self.locationError = "Auto-location unavailable. Use Settings to enter coordinates manually."
            }
        }
    }

    /// Start continuous location updates
    func startUpdating() {
        print("📍 [Location] startUpdating called, status: \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .authorized:
            print("📍 [Location] ✅ Authorized — starting updates")
            clManager.startUpdatingLocation()
        case .notDetermined:
            print("📍 [Location] ⏳ Not determined — requesting auth")
            clManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("📍 [Location] ❌ Denied/restricted")
            locationError = "Location access denied. Enable in System Settings → Privacy → Location Services → SalahTime."
            cityName = "Location Denied"
        default:
            print("📍 [Location] ⚠️ Unknown status: \(authorizationStatus.rawValue)")
            // Try starting anyway — macOS sometimes works
            clManager.startUpdatingLocation()
        }
    }

    /// Stop location updates (save battery)
    func stopUpdating() {
        clManager.stopUpdatingLocation()
    }

    /// Get the effective coordinates (auto or manual)
    var effectiveLatitude: Double {
        let settings = AppSettings.shared
        return settings.useAutoLocation ? currentLatitude : settings.manualLatitude
    }

    var effectiveLongitude: Double {
        let settings = AppSettings.shared
        return settings.useAutoLocation ? currentLongitude : settings.manualLongitude
    }

    var effectiveCityName: String {
        let settings = AppSettings.shared
        return settings.useAutoLocation ? cityName : settings.manualCityName
    }

    var hasValidLocation: Bool {
        effectiveLatitude != 0.0 || effectiveLongitude != 0.0
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            if let error = error {
                print("📍 [Location] Geocode error: \(error.localizedDescription)")
            }
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                let country = placemark.isoCountryCode ?? ""
                DispatchQueue.main.async {
                    self.cityName = country.isEmpty ? city : "\(city), \(country)"
                    print("📍 [Location] 🏙️ City: \(self.cityName)")
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("📍 [Location] ✅ Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        locationError = nil
        hasReceivedLocation = true
        reverseGeocode(location: location)

        // We only need one good fix, then stop to save power
        stopUpdating()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 [Location] ❌ Error: \(error.localizedDescription)")
        locationError = error.localizedDescription

        // Retry up to 3 times
        retryCount += 1
        if retryCount <= 3 {
            print("📍 [Location] 🔄 Retry \(retryCount)/3...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.clManager.startUpdatingLocation()
            }
        } else {
            cityName = "Set Location in Settings"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("📍 [Location] Authorization changed: \(manager.authorizationStatus.rawValue)")

        switch manager.authorizationStatus {
        case .authorized:
            print("📍 [Location] ✅ Authorized!")
            startUpdating()
        case .denied, .restricted:
            print("📍 [Location] ❌ Denied or restricted")
            locationError = "Location access denied. Enable in System Settings → Privacy → Location Services."
            cityName = "Location Denied"
        case .notDetermined:
            print("📍 [Location] ⏳ Not determined yet")
        default:
            print("📍 [Location] ⚠️ Other status: \(manager.authorizationStatus.rawValue)")
            // Try anyway
            clManager.startUpdatingLocation()
        }
    }
}
