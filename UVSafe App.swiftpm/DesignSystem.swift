import SwiftUI

// MARK: - UV Risk Color Palette

extension Color {
    static let uvNone     = Color(hex: "#6B7280")
    static let uvLow      = Color(hex: "#22C55E")
    static let uvModerate = Color(hex: "#EAB308")
    static let uvHigh     = Color(hex: "#F97316")
    static let uvVeryHigh = Color(hex: "#EF4444")
    static let uvExtreme  = Color(hex: "#8B5CF6")

    static let cardBackground   = Color.white.opacity(0.10)
    static let cardStroke       = Color.white.opacity(0.18)
    static let labelSecondary   = Color.white.opacity(0.70)
    static let labelTertiary    = Color.white.opacity(0.45)

    /// Hex initialiser
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Risk Color helper

extension UVRiskCategory {
    var swiftUIColor: Color {
        switch self {
        case .none:     return .uvNone
        case .low:      return .uvLow
        case .moderate: return .uvModerate
        case .high:     return .uvHigh
        case .veryHigh: return .uvVeryHigh
        case .extreme:  return .uvExtreme
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .none:
            return LinearGradient(colors: [Color(hex: "#374151"), Color(hex: "#1F2937")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .low:
            return LinearGradient(colors: [Color(hex: "#16A34A"), Color(hex: "#14532D")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .moderate:
            return LinearGradient(colors: [Color(hex: "#CA8A04"), Color(hex: "#713F12")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .high:
            return LinearGradient(colors: [Color(hex: "#EA580C"), Color(hex: "#7C2D12")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .veryHigh:
            return LinearGradient(colors: [Color(hex: "#DC2626"), Color(hex: "#7F1D1D")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .extreme:
            return LinearGradient(colors: [Color(hex: "#7C3AED"), Color(hex: "#3B0764")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Time-of-Day Theme

enum TimeOfDay: Equatable {
    case night        // 00:00 – 05:00
    case dawn         // 05:00 – 07:00
    case morning      // 07:00 – 11:00
    case afternoon    // 11:00 – 17:00
    case dusk         // 17:00 – 20:00
    case evening      // 20:00 – 24:00

    /// Derive from a Date's hour component
    static func from(date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 0..<5:  return .night
        case 5..<7:  return .dawn
        case 7..<11: return .morning
        case 11..<17: return .afternoon
        case 17..<20: return .dusk
        default:     return .evening
        }
    }

    /// Realistic sky gradient colours (top → bottom) for each period
    var skyColors: [Color] {
        switch self {
        case .night:
            // Near-black starry sky
            return [Color(hex: "#000005"), Color(hex: "#03031A"), Color(hex: "#060620")]
        case .dawn:
            // Dark purple melting into warm amber horizon
            return [Color(hex: "#120820"), Color(hex: "#7B2260"), Color(hex: "#D4500A"), Color(hex: "#F5A623")]
        case .morning:
            // Bright yellow-golden-orange sky
            return [Color(hex: "#FF8C00"), Color(hex: "#FFA726"), Color(hex: "#FFD54F"), Color(hex: "#FFECB3")]
        case .afternoon:
            // Bright white near horizon, vivid blue overhead — noon clarity
            return [Color(hex: "#E8F7FF"), Color(hex: "#B3DEFF"), Color(hex: "#56B4E9"), Color(hex: "#1B7FC4")]
        case .dusk:
            // Fiery orange-red melting into deep purple
            return [Color(hex: "#1A041C"), Color(hex: "#7B1045"), Color(hex: "#D93000"), Color(hex: "#FF6F00")]
        case .evening:
            // Deep navy almost black
            return [Color(hex: "#000005"), Color(hex: "#080820"), Color(hex: "#101030")]
        }
    }

    var label: String {
        switch self {
        case .night:     return "Night"
        case .dawn:      return "Dawn"
        case .morning:   return "Morning"
        case .afternoon: return "Afternoon"
        case .dusk:      return "Dusk"
        case .evening:   return "Evening"
        }
    }

    var icon: String {
        switch self {
        case .night:     return "moon.stars.fill"
        case .dawn:      return "sunrise.fill"
        case .morning:   return "sun.horizon.fill"
        case .afternoon: return "sun.max.fill"
        case .dusk:      return "sunset.fill"
        case .evening:   return "moon.fill"
        }
    }
}

// MARK: - Background Gradient

struct AppBackground: View {
    var riskCategory: UVRiskCategory = .none
    var timeOfDay: TimeOfDay = .afternoon
    /// Decimal hour 0–23.999 for precise celestial positioning
    var decimalHour: Double = 12

    var body: some View {
        ZStack {
            // ── 1. Sky colour base ──────────────────────────────────────
            LinearGradient(
                colors: timeOfDay.skyColors,
                startPoint: .top,
                endPoint: .bottom
            )

            // ── 2. Sun & Moon arc ───────────────────────────────────────
            SkyBodyView(decimalHour: decimalHour)

            // ── 3. UV risk tinted overlay (screen blend) ────────────────
            riskCategory.gradient
                .opacity(0.18)
                .blendMode(.screen)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.4), value: timeOfDay)
        .animation(.easeInOut(duration: 0.8), value: riskCategory.rawValue)
    }
}

// MARK: - Celestial Body Arc

/// Positions a sun or moon along a natural semicircular arc.
/// Sun: rises at 06:00 (left), peaks at 12:00 (top-centre), sets at 18:00 (right).
/// Moon: rises at 18:00 (right), peaks at 00:00 (top-centre), sets at 06:00 (left).
struct SkyBodyView: View {
    let decimalHour: Double   // 0 – 23.999

    // ── Sun geometry ────────────────────────────────────────────────────
    private var sunFrac: Double { ((decimalHour - 6) / 12).clamped(to: 0...1) }
    private var sunVisible: Bool {
        let f = (decimalHour - 6) / 12
        return f > -0.08 && f < 1.08
    }
    private var sunOpacity: Double {
        let f = (decimalHour - 6) / 12
        let fade = 0.10
        if f < fade  { return max(0, f / fade) }
        if f > 1 - fade { return max(0, (1 - f) / fade) }
        return 1
    }
    // x: travels left→right across full width
    // y: semicircle confined to top 25% — peak at 4%, horizon endpoints at 25%
    private var sunXFrac: Double { 0.05 + 0.90 * sunFrac }
    private var sunYFrac: Double { 0.04 + 0.21 * (1 - sin(sunFrac * .pi)) }

    // ── Moon geometry ─────────────────────────────────────────────────
    private var moonFrac: Double {
        let mh = decimalHour >= 18 ? decimalHour - 18 : decimalHour + 6
        return (mh / 12).clamped(to: 0...1)
    }
    private var moonVisible: Bool { decimalHour < 6.1 || decimalHour >= 17.9 }
    private var moonOpacity: Double {
        let f = moonFrac
        let fade = 0.10
        if f < fade  { return max(0, f / fade) * 0.88 }
        if f > 1 - fade { return max(0, (1 - f) / fade) * 0.88 }
        return 0.88
    }
    private var moonXFrac: Double { 0.05 + 0.90 * moonFrac }
    private var moonYFrac: Double { 0.04 + 0.21 * (1 - sin(moonFrac * .pi)) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Sun
                if sunVisible {
                    SunCircle()
                        .position(x: w * sunXFrac, y: h * sunYFrac)
                        .opacity(sunOpacity)
                }
                // Moon
                if moonVisible {
                    MoonCircle()
                        .position(x: w * moonXFrac, y: h * moonYFrac)
                        .opacity(moonOpacity)
                }
            }
            .animation(.easeInOut(duration: 1.2), value: decimalHour)
        }
    }
}

// MARK: - Sun

private struct SunCircle: View {
    var body: some View {
        ZStack {
            // Outer diffuse halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#FFD700").opacity(0.25), .clear],
                        center: .center, startRadius: 30, endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
            // Mid glow
            Circle()
                .fill(Color(hex: "#FFA500").opacity(0.30))
                .frame(width: 90, height: 90)
                .blur(radius: 6)
            // Solar disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#FFFFF0"), Color(hex: "#FFE066"), Color(hex: "#FF8C00")],
                        center: .center, startRadius: 0, endRadius: 28
                    )
                )
                .frame(width: 58, height: 58)
                .shadow(color: Color(hex: "#FF8C00").opacity(0.8), radius: 20)
        }
    }
}

// MARK: - Moon

private struct MoonCircle: View {
    var body: some View {
        ZStack {
            // Soft lunar glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#CBD5FF").opacity(0.18), .clear],
                        center: .center, startRadius: 22, endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
            // Moon disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#F0F4FF"), Color(hex: "#C5CAE9"), Color(hex: "#7986CB")],
                        center: .center, startRadius: 0, endRadius: 20
                    )
                )
                .frame(width: 44, height: 44)
            // Crescent shadow
            Circle()
                .fill(Color(hex: "#050520").opacity(0.82))
                .frame(width: 38, height: 38)
                .offset(x: 12, y: -8)
        }
    }
}

// MARK: - Clamping helper

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Modern iOS 18 Card

/// Reusable card style matching iOS 18's filled-material appearance:
/// - Opaque material fill (no see-through glass border)
/// - Soft inner light shimmer at the top edge
/// - Ambient shadow without a visible outline stroke
struct GlassCard<Content: View>: View {
    var content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    // Subtle tint so cards are distinguishable from each other
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.07), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                    // Inner shimmer: hairline white arc at the very top
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.clear],
                                    startPoint: .top,
                                    endPoint: .init(x: 0.5, y: 0.18)
                                )
                            )
                            .frame(height: 48)
                            .clipped()
                    }
            }
            // No stroke — depth is conveyed through shadow alone
            .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 8)
            .shadow(color: .black.opacity(0.10), radius: 4,  x: 0, y: 2)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.labelSecondary)
            .textCase(.uppercase)
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Slider Row

struct LabeledSlider: View {
    let label: String
    let icon: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    var format: String = "%.0f"

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(String(format: format, value.wrappedValue) + " " + unit)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
            Slider(value: value, in: range, step: step)
                .tint(.white.opacity(0.85))
        }
    }
}

// MARK: - Animated UV Gauge Ring

struct UVGaugeRing: View {
    let uvIndex: Double
    let riskColor: Color
    @State private var animatedProgress: Double = 0

    private let maxUVI: Double = 16

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(90))

            // Filled arc
            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [.uvLow, .uvModerate, .uvHigh, .uvVeryHigh, .uvExtreme, riskColor],
                        center: .center,
                        startAngle: .degrees(108),
                        endAngle: .degrees(432)
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(90))
                .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedProgress)

            // Centre label
            VStack(spacing: 2) {
                Text(String(format: "%.1f", max(uvIndex, 0)))
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("UV INDEX")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.labelSecondary)
                    .tracking(2)
            }
        }
        .frame(width: 200, height: 200)
        .onAppear { animatedProgress = min(uvIndex / maxUVI, 1) }
        .onChange(of: uvIndex) { newValue in
            animatedProgress = min(newValue / maxUVI, 1)
        }
    }
}
