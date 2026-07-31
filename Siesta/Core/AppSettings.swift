import Foundation
import Observation
import ServiceManagement
import os

@MainActor
@Observable
final class AppSettings {
    private static let logger = Logger(category: "settings")

    var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            syncLoginItem()
        }
    }
    var showCountdownInMenuBar: Bool {
        didSet { defaults.set(showCountdownInMenuBar, forKey: Keys.showCountdown) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showCountdownInMenuBar = defaults.bool(forKey: Keys.showCountdown)
    }

    private func syncLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            let action = self.launchAtLogin ? "register" : "unregister"
            Self.logger.error("failed to \(action) login item: \(error.localizedDescription)")
        }
    }

    private enum Keys {
        static let showCountdown = "app.showCountdownInMenuBar"
    }
}
