import SwiftUI

@main
struct MyApp: App {
    @StateObject private var settings = AccessibilitySettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
