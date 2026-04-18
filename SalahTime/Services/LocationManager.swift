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

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyKilometer  // Low power, sufficient for prayer times
        clManager.distanceFilter = 1000  // Update only on 1km movement
    }

    // MARK: - Public API

    /// Request location permission and start updating
    func requestLocation() {
        clManager.requestWhenInUseAuthorization()
    }

    /// Start continuous location updates
    func startUpdating() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocation()
            return
        }
        clManager.startUpdatingLocation()
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
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                let country = placemark.isoCountryCode ?? ""
                DispatchQueue.main.async {
                    self.cityName = country.isEmpty ? city : "\(city), \(country)"
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        locationError = nil
        reverseGeocode(location: location)

        // We only need one good fix, then stop to save power
        stopUpdating()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied, .restricted:
            locationError = "Location access denied. Enable in System Settings."
            cityName = "Location Unavailable"
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
