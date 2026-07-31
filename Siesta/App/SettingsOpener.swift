import AppKit
import SwiftUI

extension Notification.Name {
    static let siestaOpenSettings = Notification.Name("dev.abgeo.siesta.openSettings")
}

struct SettingsOpener: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 100, height: 40)
            .background(HiddenWindowConfigurator())
            .onReceive(NotificationCenter.default.publisher(for: .siestaOpenSettings)) { _ in
                Task { @MainActor in
                    // A menu-bar agent is `.accessory`; promote it so the
                    // Settings window can take focus and appear in the Dock /
                    // Cmd-Tab. `SettingsView.onDisappear` restores `.accessory`.
                    NSApp.setActivationPolicy(.regular)
                    try? await Task.sleep(for: .milliseconds(80))
                    NSApp.activate(ignoringOtherApps: true)
                    openSettings()
                }
            }
    }
}

/// Hides the host window of `SettingsOpener`, which only needs to exist so the
/// view stays in the scene graph, never to be seen. Avoids mutating
/// `styleMask`, which throws a layout exception on a SwiftUI-managed window.
private struct HiddenWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { HidingView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    /// Hides synchronously the instant it attaches, before AppKit draws it, so
    /// no transparent ghost flashes at launch.
    private final class HidingView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.alphaValue = 0
            window.isOpaque = false
            window.hasShadow = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.isExcludedFromWindowsMenu = true
            window.isRestorable = false
            window.collectionBehavior = [.transient, .ignoresCycle]
            window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
            window.orderOut(nil)
        }
    }
}
