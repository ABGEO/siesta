import SwiftUI

@main
struct SiestaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let services = AppServices.shared

    var body: some Scene {
        // A hidden scene whose only job is to hold SwiftUI's `openSettings`
        // action so the AppKit menu can trigger it. Must be declared *before*
        // the Settings scene for the environment to propagate.
        Window("", id: "settings-opener") {
            SettingsOpener()
        }

        Settings {
            SettingsView()
                .environment(services.registry)
                .environment(services.settings)
                // Drop back to a menu-bar agent when Settings closes.
                .onDisappear { NSApp.setActivationPolicy(.accessory) }
        }
    }
}
