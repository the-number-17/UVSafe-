import Foundation
import CoreLocation
import Combine

/// Wraps CoreLocation to provide real-time latitude and longitude.
/// Publishes updates via @Published properties so the ViewModel can observe them.
@MainActor
final class LocationManager: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {

    // MARK: Published State
    @Published var latitude: Double  = 0.0
    @Published var longitude: Double = 0.0

    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var hasLocation: Bool = false

    // MARK: Private
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50   // update every 50 m
    }

    // MARK: - Public API

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Read the status on this (nonisolated) thread — CLAuthorizationStatus is Sendable.
        // We must NOT capture `manager` (a non-Sendable CLLocationManager) inside the Task.
        let status = manager.authorizationStatus
        Task { @MainActor in
            locationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                locationError = nil
                // self.manager is Main-Actor-isolated, so accessing it here is safe.
                self.manager.startUpdatingLocation()
            case .denied, .restricted:
                locationError = "Location access denied. Enable it in Settings to use your device location."
            case .notDetermined:
                self.manager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            latitude  = loc.coordinate.latitude
            longitude = loc.coordinate.longitude
            hasLocation = true
            locationError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
        }
    }
}
