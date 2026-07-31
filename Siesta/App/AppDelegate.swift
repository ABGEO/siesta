import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(category: "deeplink")

    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItemController = StatusItemController(services: .shared)
    }

    /// The app lives in the menu bar via a status item, not a window, so it
    /// must not quit when its (hidden/settings) windows close.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            route(url)
        }
    }

    private func route(_ url: URL) {
        guard url.scheme == "dev.abgeo.siesta" else {
            Self.logger.debug("ignored (scheme): \(url)")
            return
        }

        // Providers differ on redirect URI shape (e.g. with or without an
        // authority component), so fold the host, if any, back in front of the
        // path to get the same ["auth", "callback", "<id>"] segments either way.
        let segments = [url.host].compactMap { $0 } + url.pathComponents.filter { $0 != "/" }

        guard segments.first == "auth" else {
            Self.logger.error("unhandled: \(url)")
            return
        }

        let handled = AppServices.shared.registry.routeCallback(url)
        Self.logger.info("auth callback \(url), handled=\(handled)")
    }
}
