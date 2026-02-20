# ☀️ UVSafe

**UVSafe** is an offline iOS Swift Playground app that estimates the UV Index and calculates time-to-sunburn using physics-based solar radiation models — no internet connection required.

> Built for Swift Student Challenge 2025

---

## Features

- **Offline UV Index Estimation** — Physics-based calculation using solar geometry (declination, hour angle, zenith angle) and atmospheric attenuation.
- **Sunburn Time Calculator** — Estimates time-to-sunburn based on UV Index, skin type (Fitzpatrick Scale I–VI), and SPF of applied sunscreen.
- **Location-Aware** — Uses Core Location to automatically fetch latitude, longitude, and altitude for accurate solar calculations.
- **Manual Input Fallback** — Fine-tune latitude, longitude, altitude, date & time, ozone column, and aerosol optical depth manually.
- **Beautiful SwiftUI Interface** — Clean, modern design with dynamic UV level indicators and result cards.
- **MVVM Architecture** — Well-structured codebase with clear separation of concerns.

---

## How It Works

### UV Index Calculation
The app estimates UV Index using a simplified radiative transfer model:

1. **Solar Declination & Hour Angle** — Derived from date/time and location.
2. **Solar Zenith Angle** — Computed from declination, latitude, and hour angle.
3. **Atmospheric Attenuation** — Models ozone absorption and Rayleigh/Mie scattering using aerosol optical depth.
4. **Altitude Correction** — UV increases ~6–8% per 1000 m of elevation.

### Sunburn Time Calculation
Based on the Ultraviolet Index standard:
- `MED` (Minimal Erythemal Dose) is determined by Fitzpatrick skin type.
- SPF multiplier is applied to extend protection time.
- Result: estimated minutes until sunburn under current UV conditions.

---

## Project Structure

```
UVSafe App.swiftpm/
├── MyApp.swift          # App entry point
├── ContentView.swift    # Root view / navigation
├── UVViewModel.swift    # ViewModel — business logic bridge
├── UVCalculator.swift   # Core physics engine (UV Index & sunburn)
├── LocationManager.swift# Core Location wrapper
├── UVInputView.swift    # Input parameters form
├── UVResultView.swift   # Results display
├── DesignSystem.swift   # Colors, typography, reusable UI components
└── Package.swift        # Swift Playground package manifest
```

---

## Requirements

- **Platform**: iOS 16+
- **IDE**: Swift Playgrounds 4+ or Xcode 15+
- **Frameworks**: SwiftUI, Core Location

---

## Getting Started

1. Clone or download this repository.
2. Open `UVSafe App.swiftpm` in **Swift Playgrounds** (on iPad or Mac) or **Xcode**.
3. Run the app on your device or simulator.
4. Grant location access when prompted, or enter coordinates manually.

---

## Screenshots

> *Coming soon*

---

## Author

**Aviral Singh**  
Swift Student Challenge 2025 Submission

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
