import Foundation

// MARK: - Supporting Enums

enum CloudCondition: String, CaseIterable, Identifiable {
    case clear = "Clear"
    case partlyCloudy = "Partly Cloudy"
    case overcast = "Overcast"

    var id: String { rawValue }

    /// Cloud attenuation factor applied to UV transmission
    var transmissionFactor: Double {
        switch self {
        case .clear:        return 1.0
        case .partlyCloudy: return 0.75
        case .overcast:     return 0.40
        }
    }

    var sfSymbol: String {
        switch self {
        case .clear:        return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .overcast:     return "cloud.fill"
        }
    }
}

/// Fitzpatrick skin type with associated MED (Minimal Erythemal Dose) in J/m²
enum SkinType: String, CaseIterable, Identifiable {
    case typeI   = "Type I — Very Fair"
    case typeII  = "Type II — Fair"
    case typeIII = "Type III — Medium"
    case typeIV  = "Type IV — Olive"
    case typeV   = "Type V — Brown"
    case typeVI  = "Type VI — Dark Brown/Black"

    var id: String { rawValue }

    /// Minimal Erythemal Dose in J/m² (energy required to cause initial sunburn redness)
    var med: Double {
        switch self {
        case .typeI:   return 200
        case .typeII:  return 250
        case .typeIII: return 300
        case .typeIV:  return 450
        case .typeV:   return 600
        case .typeVI:  return 1000
        }
    }

    var shortName: String {
        switch self {
        case .typeI:   return "I"
        case .typeII:  return "II"
        case .typeIII: return "III"
        case .typeIV:  return "IV"
        case .typeV:   return "V"
        case .typeVI:  return "VI"
        }
    }
    var description: String {
        switch self {
        case .typeI:   return "Always burns, never tans"
        case .typeII:  return "Usually burns, rarely tans"
        case .typeIII: return "Sometimes burns, gradually tans"
        case .typeIV:  return "Rarely burns, always tans"
        case .typeV:   return "Very rarely burns, tans darkly"
        case .typeVI:  return "Never burns, deeply pigmented"
        }
    }
}

enum UVRiskCategory: String {
    case low      = "Low"
    case moderate = "Moderate"
    case high     = "High"
    case veryHigh = "Very High"
    case extreme  = "Extreme"
    case none     = "None (Sun Below Horizon)"

    var color: String {
        switch self {
        case .none:     return "#6B7280"
        case .low:      return "#22C55E"
        case .moderate: return "#EAB308"
        case .high:     return "#F97316"
        case .veryHigh: return "#EF4444"
        case .extreme:  return "#8B5CF6"
        }
    }

    var recommendation: String {
        switch self {
        case .none:
            return "The sun is below the horizon — no UV risk at this time."
        case .low:
            return "UV risk is low. You can safely enjoy outdoor activities. No special protection needed for most people."
        case .moderate:
            return "Take precautions — wear sunscreen SPF 30+, protective clothing, and a hat. Seek shade near midday."
        case .high:
            return "Protection is essential. Reduce sun exposure between 10am–4pm. Apply SPF 50+ every 2 hours."
        case .veryHigh:
            return "Extra protection required. Avoid sun exposure near midday. Unprotected skin can burn quickly."
        case .extreme:
            return "Extreme UV levels — try to stay indoors. If outdoors, wear full-body protection, SPF 50+ and UV-blocking sunglasses."
        }
    }
}

// MARK: - UV Calculation Result

struct UVResult {
    let uvIndex: Double
    let uvPowerWattsPerM2: Double
    let riskCategory: UVRiskCategory
    let burnTimeSeconds: Double        // without SPF (but with skin type)
    let burnTimeWithSPFSeconds: Double // with SPF
    let solarZenithDegrees: Double
    let isSunBelowHorizon: Bool

    /// Lower bound of burn time range (−20% uncertainty)
    var burnTimeMinMinutes: Double { (burnTimeWithSPFSeconds * 0.80) / 60 }
    /// Upper bound of burn time range (+20% uncertainty)
    var burnTimeMaxMinutes: Double { (burnTimeWithSPFSeconds * 1.20) / 60 }

    static var sunBelowHorizon: UVResult {
        UVResult(uvIndex: 0, uvPowerWattsPerM2: 0, riskCategory: .none,
                 burnTimeSeconds: .infinity, burnTimeWithSPFSeconds: .infinity,
                 solarZenithDegrees: 90, isSunBelowHorizon: true)
    }
}

// MARK: - UV Calculator

struct UVCalculator {

    // MARK: Constants
    /// Base UV irradiance constant at sea level, clear sky, no pollution (W/m²)
    /// Calibrated so that cos(θ)=1 and full transmission → UVIndex ≈ 11–12 (extreme)
    private static let baseUVConstant: Double = 0.302

    /// Aerosol attenuation coefficient (per AQI unit)
    private static let aerosolK: Double = 0.002

    // MARK: - Main Entry Point

    /// Compute UV Index, risk, and sunburn time from all environmental and personal inputs.
    static func calculate(
        latitude: Double,            // degrees
        longitude: Double,           // degrees
        date: Date,
        altitude: Double,            // metres (above sea level)
        aqiPollution: Double,        // Air Quality Index (0–500)
        cloudCondition: CloudCondition,
        skinType: SkinType,
        sunscreenSPF: Double         // 1.0 = no sunscreen, 50 = SPF 50
    ) -> UVResult {

        // ── 1. Day of Year ───────────────────────────────────────────────────
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)

        // ── 2. Solar Declination δ ───────────────────────────────────────────
        // δ = 23.45° × sin(360/365 × (284 + N))  where N = day of year
        // This approximates Earth's axial tilt effect on solar angle.
        let declinationDeg = 23.45 * sin(toRadians(360.0 / 365.0 * (284.0 + dayOfYear)))
        let declinationRad = toRadians(declinationDeg)

        // ── 3. Local Solar Time & Hour Angle H ───────────────────────────────
        // Equation of Time (minutes) — sinusoidal approximation
        let B = toRadians(360.0 / 365.0 * (dayOfYear - 81))
        let eqOfTime = 9.87 * sin(2 * B) - 7.53 * cos(B) - 1.5 * sin(B)   // minutes

        // Time zone offset from UTC in hours (using longitude ÷ 15)
        let timezoneOffsetHours = longitude / 15.0

        // Local standard time in fractional hours
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let localStandardHours = Double(components.hour ?? 12)
                                + Double(components.minute ?? 0) / 60.0
                                + Double(components.second ?? 0) / 3600.0

        // Longitude correction: 4 min per degree difference from standard meridian
        let longitudeCorrection = 4.0 * (longitude - 15.0 * timezoneOffsetHours.rounded()) / 60.0

        // Local Solar Time in hours
        let localSolarTime = localStandardHours + longitudeCorrection + eqOfTime / 60.0

        // Hour angle H: 0° at solar noon, +15° per hour after, −15° per hour before
        let hourAngleDeg = 15.0 * (localSolarTime - 12.0)
        let hourAngleRad = toRadians(hourAngleDeg)

        // ── 4. Solar Zenith Angle θ ──────────────────────────────────────────
        // cos(θ) = sin(φ)sin(δ) + cos(φ)cos(δ)cos(H)
        // φ = latitude, δ = declination, H = hour angle
        let latRad = toRadians(latitude)
        let cosZenith = sin(latRad) * sin(declinationRad)
                       + cos(latRad) * cos(declinationRad) * cos(hourAngleRad)

        // If cos(θ) ≤ 0 the sun is at or below the horizon → no UV
        guard cosZenith > 0.0 else {
            return .sunBelowHorizon
        }

        let zenithDeg = toDegrees(acos(min(cosZenith, 1.0)))

        // ── 5. Ozone Column Estimate (Dobson Units) ──────────────────────────
        // Latitude-based climatological mean plus seasonal sinusoidal correction.
        let absLat = abs(latitude)
        let baseDU: Double
        let seasonalAmplitude: Double

        if absLat <= 20 {
            baseDU = 260; seasonalAmplitude = 10
        } else if absLat <= 40 {
            baseDU = 285; seasonalAmplitude = 15
        } else {
            baseDU = 310; seasonalAmplitude = 20
        }

        // Peak ozone around early spring (day ~80), minimum around fall
        let ozoneDU = baseDU + seasonalAmplitude * sin(toRadians(360.0 / 365.0 * (dayOfYear - 80)))

        // Ozone UV attenuation: Beer–Lambert approximation
        // Using a simplified cross-section factor; effective at erythemally weighted UV
        let ozoneFactor = exp(-0.0003 * (ozoneDU - 250.0))   // relative to 250 DU reference

        // ── 6. Atmospheric Transmission Factor ──────────────────────────────

        // 6a. Pollution (aerosol) correction using Beer–Lambert law:
        // τ_aerosol = exp(−k × AQI) where k ≈ 0.002
        let pollutionFactor = exp(-aerosolK * max(aqiPollution, 0))

        // 6b. Cloud correction (empirical attenuation factors)
        let cloudFactor = cloudCondition.transmissionFactor

        // 6c. Altitude correction: UV increases ~10% per 1000 m due to thinner atmosphere
        let altitudeFactor = 1.0 + 0.1 * (altitude / 1000.0)

        // Combined transmission
        let totalTransmission = ozoneFactor * pollutionFactor * cloudFactor * altitudeFactor

        // ── 7. UV Power & UV Index ───────────────────────────────────────────
        // UV irradiance at surface (W/m² erythemally weighted):
        //   UV_power = baseConstant × cos(θ) × transmission
        let uvPower = baseUVConstant * cosZenith * totalTransmission

        // UV Index = UV_power / 0.025 (W/m²)
        // (Standard conversion: 1 UVI ≡ 0.025 W/m² erythemally weighted irradiance)
        let uvIndex = uvPower / 0.025

        // ── 8. Risk Category ─────────────────────────────────────────────────
        let risk: UVRiskCategory
        switch uvIndex {
        case ..<0:    risk = .none
        case 0..<3:   risk = .low
        case 3..<6:   risk = .moderate
        case 6..<8:   risk = .high
        case 8..<11:  risk = .veryHigh
        default:      risk = .extreme
        }

        // ── 9. Sunburn Time ──────────────────────────────────────────────────
        // MED = Minimal Erythemal Dose (J/m²) for this skin type
        // Time_to_burn = MED / UV_power (seconds)
        // With SPF: time_to_burn *= SPF (linear protection model)
        let spf = max(sunscreenSPF, 1.0)
        let burnTimeSeconds: Double
        let burnTimeWithSPF: Double

        if uvPower > 0 {
            burnTimeSeconds  = skinType.med / uvPower
            burnTimeWithSPF  = burnTimeSeconds * spf
        } else {
            burnTimeSeconds  = .infinity
            burnTimeWithSPF  = .infinity
        }

        return UVResult(
            uvIndex: uvIndex,
            uvPowerWattsPerM2: uvPower,
            riskCategory: risk,
            burnTimeSeconds: burnTimeSeconds,
            burnTimeWithSPFSeconds: burnTimeWithSPF,
            solarZenithDegrees: zenithDeg,
            isSunBelowHorizon: false
        )
    }

    // MARK: - Helpers

    private static func toRadians(_ deg: Double) -> Double { deg * .pi / 180 }
    private static func toDegrees(_ rad: Double) -> Double { rad * 180 / .pi }
}
