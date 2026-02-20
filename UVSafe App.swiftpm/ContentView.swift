import SwiftUI

struct ContentView: View {
    @StateObject private var vm = UVViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
            // Dynamic gradient background — responds to UV risk, time of day, and precise hour
            AppBackground(
                riskCategory: vm.uvResult?.riskCategory ?? .none,
                timeOfDay: vm.timeOfDay,
                decimalHour: vm.decimalHour
            )

            VStack(spacing: 0) {
                // ── Header Bar ────────────────────────────────────────────
                HeaderBar(vm: vm)

                // ── Location Permission Banner ────────────────────────────
                if let err = vm.locationManager.locationError {
                    LocationErrorBanner(message: err)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // ── Tab Selector ──────────────────────────────────────────
                TabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                // ── Scrollable Content ────────────────────────────────────
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            // Results tab
                            if !vm.locationManager.hasLocation {
                                LocationWaitingCard(vm: vm)
                            } else {
                                UVResultView(vm: vm)
                            }
                        } else {
                            // Settings tab
                            UVInputView(vm: vm)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .animation(.easeInOut(duration: 0.4), value: selectedTab)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            vm.locationManager.requestPermission()
        }
    }
}

// MARK: - Header Bar

private struct HeaderBar: View {
    @ObservedObject var vm: UVViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // App icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                Image(systemName: vm.timeOfDay.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: iconColors(for: vm.timeOfDay),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(vm.isCalculating ? 1.18 : 1.0)
                    .animation(
                        vm.isCalculating
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                            : .easeInOut(duration: 0.2),
                        value: vm.isCalculating
                    )
                    .animation(.easeInOut(duration: 0.6), value: vm.timeOfDay)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("UVSafe")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                // Time-of-day badge inline under the title
                HStack(spacing: 4) {
                    Image(systemName: vm.timeOfDay.icon)
                        .font(.system(size: 10))
                    Text(vm.timeOfDay.label)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color.white.opacity(0.65))
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.5), value: vm.timeOfDay)
            }

            Spacer()

            // Live indicator
            LiveIndicator(hasLocation: vm.locationManager.hasLocation)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func iconColors(for tod: TimeOfDay) -> [Color] {
        switch tod {
        case .night:     return [Color(hex: "#C0C0FF"), Color(hex: "#8080CC")]
        case .dawn:      return [Color(hex: "#FF9999"), Color(hex: "#FF6644")]
        case .morning:   return [Color(hex: "#FFE066"), Color(hex: "#FFA040")]
        case .afternoon: return [Color(hex: "#FFEE44"), Color(hex: "#FF9900")]
        case .dusk:      return [Color(hex: "#FF8844"), Color(hex: "#CC4488")]
        case .evening:   return [Color(hex: "#AAAAFF"), Color(hex: "#6644AA")]
        }
    }
}

private struct LiveIndicator: View {
    let hasLocation: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(hasLocation ? Color.uvLow : Color.uvModerate)
                .frame(width: 7, height: 7)
                .scaleEffect(pulse ? 1.3 : 1.0)
                .shadow(color: (hasLocation ? Color.uvLow : Color.uvModerate).opacity(0.7), radius: pulse ? 5 : 2)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }
            Text(hasLocation ? "LIVE" : "WAITING")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(hasLocation ? Color.uvLow : Color.uvModerate)
                .tracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Location Banners

private struct LocationErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
}

private struct LocationWaitingCard: View {
    @ObservedObject var vm: UVViewModel
    @State private var rotationAngle: Double = 0

    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom)
                    )
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotationAngle)
                    .onAppear { rotationAngle = 360 }

                VStack(spacing: 8) {
                    Text("Acquiring Location")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Allow location access to get real-time UV estimates for your current position.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.labelSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                if vm.locationManager.locationStatus == .notDetermined {
                    Button {
                        vm.locationManager.requestPermission()
                    } label: {
                        Text("Grant Location Access")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing),
                                in: Capsule()
                            )
                            .shadow(color: .cyan.opacity(0.4), radius: 8, y: 4)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Tab Selector

private struct TabSelector: View {
    @Binding var selectedTab: Int
    private let tabs   = ["Results", "Settings"]
    private let icons  = ["sun.max.fill", "slider.horizontal.3"]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)

                // Sliding indicator
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.white.opacity(0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: proxy.size.width / 2 - 4)
                    .offset(x: selectedTab == 0 ? 3 : proxy.size.width / 2 + 1)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: selectedTab)

                // Labels
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { i in
                        Button {
                            withAnimation { selectedTab = i }
                        } label: {
                            Label(tabs[i], systemImage: icons[i])
                                .font(.system(size: 14, weight: selectedTab == i ? .bold : .medium))
                                .foregroundStyle(selectedTab == i ? .white : Color.white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                    }
                }
            }
        }
        .frame(height: 46)
    }
}
