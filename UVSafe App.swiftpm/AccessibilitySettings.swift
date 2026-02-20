import SwiftUI

/// Holds app-wide accessibility preferences, persisted across launches.
@MainActor
final class AccessibilitySettings: ObservableObject {
    static let shared = AccessibilitySettings()

    /// When true, all UV risk colours switch to the Okabe-Ito colorblind-safe palette,
    /// avoiding the red/green contrast that is invisible to deuteranopic/protanopic users.
    @AppStorage("colorBlindMode") var colorBlindMode: Bool = false

    private init() {}
}
