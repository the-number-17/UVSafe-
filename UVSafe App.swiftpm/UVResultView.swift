import SwiftUI

/// The main result display with animated UV gauge, risk badge, and burn time card.
struct UVResultView: View {
    @ObservedObject var vm: UVViewModel
    @State private var appeared = false

    var result: UVResult? { vm.uvResult }
    var risk: UVRiskCategory { result?.riskCategory ?? .none }

    var body: some View {
        VStack(spacing: 20) {

            // ── Gauge Ring ──────────────────────────────────────────────────
            GaugeSection(vm: vm, appeared: appeared)

            // ── Risk Badge ─────────────────────────────────────────────────
            RiskBadge(risk: risk)
                .transition(.scale.combined(with: .opacity))

            // ── Stats Row ─────────────────────────────────────────────────
            StatsRow(vm: vm, result: result)
                .transition(.move(edge: .bottom).combined(with: .opacity))

            // ── Burn Time Card ────────────────────────────────────────────
            BurnTimeCard(vm: vm, result: result)
                .transition(.move(edge: .bottom).combined(with: .opacity))

            // ── Recommendation ────────────────────────────────────────────
            RecommendationCard(risk: risk)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Gauge Section

private struct GaugeSection: View {
    @ObservedObject var vm: UVViewModel
    let appeared: Bool

    var result: UVResult? { vm.uvResult }
    var risk: UVRiskCategory { result?.riskCategory ?? .none }

    var body: some View {
        GlassCard {
            VStack(spacing: 16) {
                // Location pill
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(vm.locationText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08), in: Capsule())

                // Gauge
                UVGaugeRing(
                    uvIndex: max(result?.uvIndex ?? 0, 0),
                    riskColor: risk.swiftUIColor
                )
                .scaleEffect(appeared ? 1.0 : 0.7)
                .opacity(appeared ? 1.0 : 0)
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: appeared)

                // Zenith angle info
                if let r = result, !r.isSunBelowHorizon {
                    HStack(spacing: 4) {
                        Image(systemName: "scope")
                            .font(.system(size: 11))
                        Text("Solar zenith: \(vm.zenithDescription)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.labelSecondary)
                }
            }
        }
    }
}

// MARK: - Risk Badge

private struct RiskBadge: View {
    let risk: UVRiskCategory

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(risk.swiftUIColor)
                .frame(width: 10, height: 10)
                .shadow(color: risk.swiftUIColor.opacity(0.8), radius: 6)

            Text(risk.rawValue.uppercased())
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .tracking(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(risk.swiftUIColor.opacity(0.25), in: Capsule())
        .overlay(Capsule().stroke(risk.swiftUIColor.opacity(0.55), lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.5), value: risk.rawValue)
    }
}

// MARK: - Stats Row

private struct StatsRow: View {
    @ObservedObject var vm: UVViewModel
    let result: UVResult?

    var body: some View {
        HStack(spacing: 12) {
            StatPill(
                icon: "sun.max.fill",
                label: "UV Index",
                value: result.map { String(format: "%.1f", max($0.uvIndex, 0)) } ?? "—",
                color: result?.riskCategory.swiftUIColor ?? .uvNone
            )
            StatPill(
                icon: "mountain.2.fill",
                label: "Altitude",
                value: String(format: "%.0f m", vm.locationManager.altitude),
                color: .cyan
            )
            StatPill(
                icon: "wind",
                label: "AQI",
                value: String(format: "%.0f", vm.aqiPollution),
                color: .blue
            )
        }
    }
}

private struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.labelSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .overlay(alignment: .top) {
                    // Top-edge shimmer matching GlassCard
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), Color.clear],
                                startPoint: .top,
                                endPoint: .init(x: 0.5, y: 0.25)
                            )
                        )
                        .frame(height: 36)
                        .clipped()
                }
        }
        .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.08), radius: 3,  x: 0, y: 1)
    }
}

// MARK: - Burn Time Card

private struct BurnTimeCard: View {
    @ObservedObject var vm: UVViewModel
    let result: UVResult?

    var body: some View {
        GlassCard {
            VStack(spacing: 14) {
                SectionHeader(icon: "flame.fill", title: "Sunburn Time Estimate")

                // Burn range display
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    if let r = result, !r.isSunBelowHorizon, r.uvPowerWattsPerM2 > 0 {
                        Text("≈")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.labelSecondary)
                        Text(vm.formattedBurnRange)
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("(±20%)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color.labelSecondary)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.stars.fill")
                            Text("No sunburn risk")
                        }
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.labelSecondary)
                    }
                }

                Divider().background(Color.white.opacity(0.15))

                // Skin type & SPF row
                HStack {
                    Label("Skin \(vm.skinType.shortName)", systemImage: "person.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    if vm.sunscreenSPF > 1.5 {
                        Label("SPF \(Int(vm.sunscreenSPF))", systemImage: "shield.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.cyan)
                    } else {
                        Label("No sunscreen", systemImage: "shield.slash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Recommendation Card

private struct RecommendationCard: View {
    let risk: UVRiskCategory

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(icon: "lightbulb.fill", title: "Safety Advice")
                Text(risk.recommendation)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: risk.rawValue)
    }
}
