import Foundation
import Combine
import SwiftUI

/// MVVM ViewModel — connects LocationManager, UVCalculator, and the UI.
/// All business logic lives here; the View only observes published state.
@MainActor
final class UVViewModel: ObservableObject {

    // MARK: - Published Inputs (user-adjustable)
    @Published var selectedDate: Date = Date()
    @Published var aqiPollution: Double = 50          // Air Quality Index
    @Published var cloudCondition: CloudCondition = .clear
    @Published var skinType: SkinType = .typeII
    @Published var sunscreenSPF: Double = 1.0         // 1 = no sunscreen

    // MARK: - Published Outputs
    @Published var uvResult: UVResult? = nil
    @Published var isCalculating: Bool = false

    // MARK: - Location
    let locationManager = LocationManager()

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // Start location updates immediately
        locationManager.requestPermission()

        // Recalculate whenever any input changes (debounced for performance)
        Publishers.CombineLatest4(
            $selectedDate,
            $aqiPollution,
            $cloudCondition,
            $skinType
        )
        .combineLatest($sunscreenSPF)
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in self?.calculate() }
        .store(in: &cancellables)

        // Recalculate when location updates
        locationManager.$hasLocation
            .filter { $0 }
            .sink { [weak self] _ in self?.calculate() }
            .store(in: &cancellables)

        locationManager.$latitude
            .combineLatest(locationManager.$longitude, locationManager.$altitude)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.calculate() }
            .store(in: &cancellables)
    }

    // MARK: - Calculation

    func calculate() {
        guard locationManager.hasLocation else { return }

        isCalculating = true
        let lat  = locationManager.latitude
        let lon  = locationManager.longitude
        let alt  = locationManager.altitude
        let date = selectedDate
        let aqi  = aqiPollution
        let cloud = cloudCondition
        let skin  = skinType
        let spf   = sunscreenSPF

        // Perform on background thread to keep UI smooth
        Task.detached(priority: .userInitiated) { [weak self] in
            let result = UVCalculator.calculate(
                latitude: lat,
                longitude: lon,
                date: date,
                altitude: alt,
                aqiPollution: aqi,
                cloudCondition: cloud,
                skinType: skin,
                sunscreenSPF: spf
            )
            await MainActor.run { [weak self] in
                self?.uvResult = result
                self?.isCalculating = false
            }
        }
    }

    // MARK: - Formatters

    var formattedUVIndex: String {
        guard let r = uvResult else { return "—" }
        return String(format: "%.1f", max(r.uvIndex, 0))
    }

    var formattedBurnRange: String {
        guard let r = uvResult, !r.isSunBelowHorizon, r.uvPowerWattsPerM2 > 0 else {
            return "No burn risk"
        }
        let lo = r.burnTimeMinMinutes
        let hi = r.burnTimeMaxMinutes
        if hi >= 999 { return "> 16 hours" }
        return String(format: "%.0f – %.0f min", lo, hi)
    }

    var zenithDescription: String {
        guard let r = uvResult else { return "—" }
        return String(format: "%.1f°", r.solarZenithDegrees)
    }

    /// Time-of-day period derived from the selected date's local hour
    var timeOfDay: TimeOfDay {
        TimeOfDay.from(date: selectedDate)
    }

    /// Precise decimal hour (0–23.999) used for sun/moon arc positioning
    var decimalHour: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60.0
    }

    var locationText: String {
        if locationManager.hasLocation {
            return String(format: "%.4f°, %.4f°  •  %.0f m", locationManager.latitude, locationManager.longitude, locationManager.altitude)
        }
        return "Acquiring location…"
    }
}
