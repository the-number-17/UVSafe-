import SwiftUI

/// Input controls for date/time, pollution, cloud, skin type, and SPF.
struct UVInputView: View {
    @ObservedObject var vm: UVViewModel

    var body: some View {
        VStack(spacing: 16) {

            // ── Date & Time ───────────────────────────────────────────────
            GlassCard {
                VStack(spacing: 12) {
                    SectionHeader(icon: "calendar.badge.clock", title: "Date & Time")
                    DatePicker("", selection: $vm.selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .tint(.cyan)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            // ── Pollution / AQI ──────────────────────────────────────────
            GlassCard {
                VStack(spacing: 12) {
                    SectionHeader(icon: "aqi.medium", title: "Air Quality")
                    LabeledSlider(
                        label: "Pollution Level",
                        icon: "smoke.fill",
                        value: $vm.aqiPollution,
                        range: 0...300,
                        step: 1,
                        unit: "AQI"
                    )
                    AQIHint(aqi: vm.aqiPollution)
                }
            }

            // ── Cloud Condition ──────────────────────────────────────────
            GlassCard {
                VStack(spacing: 12) {
                    SectionHeader(icon: "cloud.sun.fill", title: "Cloud Conditions")
                    Picker("Cloud", selection: $vm.cloudCondition) {
                        ForEach(CloudCondition.allCases) { c in
                            Label(c.rawValue, systemImage: c.sfSymbol)
                                .tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    .colorScheme(.dark)
                }
            }

            // ── Skin Type ────────────────────────────────────────────────
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(icon: "person.crop.circle.fill", title: "Fitzpatrick Skin Type")

                    // Visual colour-swatch palette
                    SkinPaletteSelector(selected: $vm.skinType)

                    // Detail row for the selected type
                    HStack(spacing: 10) {
                        SkinSwatchView(type: vm.skinType, size: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vm.skinType.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(vm.skinType.description)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Color.labelSecondary)
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            // ── Sunscreen SPF ─────────────────────────────────────────────
            GlassCard {
                VStack(spacing: 12) {
                    SectionHeader(icon: "shield.fill", title: "Sunscreen Protection")
                    LabeledSlider(
                        label: "SPF Factor",
                        icon: "shield.lefthalf.filled",
                        value: $vm.sunscreenSPF,
                        range: 0...120,
                        step: 1,
                        unit: "SPF"
                    )
                    HStack {
                        Text(vm.sunscreenSPF < 1 ? "No sunscreen" : spfLabel(vm.sunscreenSPF))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(vm.sunscreenSPF < 1 ? Color.uvHigh : Color.uvLow)
                        Spacer()
                        Text("0 = no protection • 50 = SPF 50")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.labelTertiary)
                    }
                }
            }
        }
    }

    private func spfLabel(_ spf: Double) -> String {
        switch spf {
        case 1..<15:  return "Low SPF"
        case 15..<30: return "Medium SPF"
        case 30..<50: return "High SPF"
        default:      return "Very High SPF"
        }
    }
}

// MARK: - AQI Hint Row

private struct AQIHint: View {
    let aqi: Double
    @EnvironmentObject var settings: AccessibilitySettings

    var label: String {
        switch aqi {
        case 0..<51:   return "Good"
        case 51..<101: return "Moderate"
        case 101..<151: return "Unhealthy for sensitive groups"
        case 151..<201: return "Unhealthy"
        case 201..<301: return "Very Unhealthy"
        default:        return "Hazardous"
        }
    }

    var color: Color {
        let cb = settings.colorBlindMode
        switch aqi {
        case 0..<51:   return cb ? .cbLow      : .uvLow
        case 51..<101: return cb ? .cbModerate  : .uvModerate
        case 101..<151: return cb ? .cbHigh     : .uvHigh
        default:        return cb ? .cbVeryHigh : .uvVeryHigh
        }
    }

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.7), radius: 4)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Skin Swatch (shared circle with configurable size)

struct SkinSwatchView: View {
    let type: SkinType
    var size: CGFloat = 22

    var fillColor: Color {
        switch type {
        case .typeI:   return Color(hex: "#FFE0C0")
        case .typeII:  return Color(hex: "#F5C5A3")
        case .typeIII: return Color(hex: "#DDA06E")
        case .typeIV:  return Color(hex: "#B87040")
        case .typeV:   return Color(hex: "#7D4A2A")
        case .typeVI:  return Color(hex: "#3D1F10")
        }
    }

    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Skin Palette Selector

private struct SkinPaletteSelector: View {
    @Binding var selected: SkinType

    // Skin tone fill colours matching Fitzpatrick scale
    private func color(for type: SkinType) -> Color {
        switch type {
        case .typeI:   return Color(hex: "#FFE0C0")
        case .typeII:  return Color(hex: "#F5C5A3")
        case .typeIII: return Color(hex: "#DDA06E")
        case .typeIV:  return Color(hex: "#B87040")
        case .typeV:   return Color(hex: "#7D4A2A")
        case .typeVI:  return Color(hex: "#3D1F10")
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(SkinType.allCases) { type in
                let isSelected = selected == type
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        selected = type
                    }
                } label: {
                    VStack(spacing: 6) {
                        // Colour circle
                        Circle()
                            .fill(color(for: type))
                            .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                            // Glowing selection ring
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected ? color(for: type) : Color.white.opacity(0.18),
                                        lineWidth: isSelected ? 3 : 1
                                    )
                                    .padding(-3)
                            )
                            .shadow(
                                color: isSelected ? color(for: type).opacity(0.7) : .clear,
                                radius: 8
                            )
                            .scaleEffect(isSelected ? 1.0 : 0.9)

                        // Roman numeral label
                        Text(type.shortName)
                            .font(.system(size: 10, weight: isSelected ? .black : .medium))
                            .foregroundStyle(isSelected ? .white : Color.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
