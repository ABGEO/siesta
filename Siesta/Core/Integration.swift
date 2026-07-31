import SwiftUI
import os

/// A third-party service the app integrates with (Slack, Google, later Teams).
///
/// Each integration fully owns itself: identity/auth (OIDC), its configuration,
/// its settings UI, its away start/stop action, and its token storage (which is
/// an internal detail, not part of this surface).
@MainActor
protocol Integration: AnyObject {
    var id: String { get }
    var displayName: String { get }
    var iconSystemName: String { get }

    /// Observable connection status.
    var connectionState: ConnectionState { get }

    /// User-facing configuration (concrete type is integration-private).
    var config: any IntegrationConfig { get }

    // MARK: Auth
    func connect() async
    func disconnect() async

    @discardableResult
    func handleCallback(_ url: URL) -> Bool

    // MARK: Siesta lifecycle
    func startAway(_ session: AwaySession) async throws
    func stopAway() async throws

    // MARK: UI contributions
    /// This integration's tab content in the Settings window.
    func settingsView() -> AnyView
}

extension Integration {
    var logger: Logger { Logger(category: id) }
}
