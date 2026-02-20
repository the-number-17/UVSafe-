import SwiftUI

/// The main result display with animated UV gauge, risk badge, and burn time card.
struct UVResultView: View {
    @ObservedObject var vm: UVViewModel
    @EnvironmentObject var settings: AccessibilitySettings
    @State private var appeared = false

    var result: UVResult? { vm.uvResult }
    var risk: UVRiskCategory { result?.riskCategory ?? .none }

    var body: some View {
        VStack(spacing: 20) {

            // ── Gauge Ring ──────────────────────────────────────────────────
            GaugeSection(vm: vm, appeared: appeared, colorBlind: settings.colorBlindMode)

            // ── Risk Badge ─────────────────────────────────────────────────
            RiskBadge(risk: risk, colorBlind: settings.colorBlindMode)
                .transition(.scale.combined(with: .opacity))

            // ── Stats Row ─────────────────────────────────────────────────
            StatsRow(vm: vm, result: result, colorBlind: settings.colorBlindMode)
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
    let colorBlind: Bool

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
                    riskColor: risk.adaptiveColor(colorBlind: colorBlind),
                    colorBlind: colorBlind
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
    let colorBlind: Bool

    var body: some View {
        let color = risk.adaptiveColor(colorBlind: colorBlind)
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.8), radius: 6)

            Text(risk.rawValue.uppercased())
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .tracking(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(color.opacity(0.25), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.55), lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.5), value: risk.rawValue)
    }
}

// MARK: - Stats Row

private struct StatsRow: View {
    @ObservedObject var vm: UVViewModel
    let result: UVResult?
    let colorBlind: Bool

    var body: some View {
        HStack(spacing: 12) {
            StatPill(
                icon: "sun.max.fill",
                label: "UV Index",
                value: result.map { String(format: "%.1f", max($0.uvIndex, 0)) } ?? "—",
                color: (result?.riskCategory ?? .none).adaptiveColor(colorBlind: colorBlind)
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
                    if vm.sunscreenSPF >= 1 {
                        Label("SPF \(Int(vm.sunscreenSPF))", systemImage: "shield.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.cyan)
                    } else {
                        Label("No sunscreen", systemImage: "shield.slash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }

                // ── Reminder button ─────────────────────────────────────────
                if let r = result, !r.isSunBelowHorizon, r.uvPowerWattsPerM2 > 0 {
                    Divider().background(Color.white.opacity(0.15))
                    ReminderButton(vm: vm, result: r)
                }
            }
        }
    }
}

// MARK: - Reminder Button

private struct ReminderButton: View {
    @ObservedObject var vm: UVViewModel
    let result: UVResult

    @ObservedObject private var nm = NotificationManager.shared
    @State private var isScheduling = false
    @State private var showDeniedAlert = false

    private var hasActiveReminder: Bool { nm.pendingReminder != nil }

    private func countdownText(now: Date) -> String {
        guard let fireDate = nm.pendingReminder else { return "" }
        let secs = max(0, fireDate.timeIntervalSince(now))
        if secs >= 3600 {
            return String(format: "%.0fh %.0fm left", floor(secs / 3600), (secs.truncatingRemainder(dividingBy: 3600)) / 60)
        }
        return String(format: "%.0f min left", ceil(secs / 60))
    }

    var body: some View {
        if hasActiveReminder {
            // ── Active state: countdown + cancel ───────────────────────────
            TimelineView(.periodic(from: .now, by: 30)) { context in
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Reminder set")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text(countdownText(now: context.date))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.labelSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            nm.cancel()
                        }
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.35), lineWidth: 1))
            .transition(.move(edge: .bottom).combined(with: .opacity))

        } else {
            // ── Idle state: "Going outside now?" button ─────────────────────
            Button {
                Task {
                    isScheduling = true
                    await nm.scheduleReminder(
                        burnSeconds: result.burnTimeWithSPFSeconds,
                        skinTypeName: vm.skinType.shortName,
                        spf: vm.sunscreenSPF
                    )
                    if nm.authStatus == .denied { showDeniedAlert = true }
                    isScheduling = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isScheduling {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.75)
                            .tint(.white)
                    } else {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isScheduling ? "Setting reminder…" : "Going outside now?")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#F97316"), Color(hex: "#DC2626")],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .shadow(color: Color(hex: "#F97316").opacity(0.45), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(isScheduling)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .alert("Notifications Disabled", isPresented: $showDeniedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Enable notifications in Settings → UVSafe to receive sunburn reminders.")
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
