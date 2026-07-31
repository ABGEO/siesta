import SwiftUI
import Observation

/// Holds every integration the app knows about. The single collection that the
/// UI and the away orchestrator iterate. Add a provider by adding it here.
@MainActor
@Observable
final class IntegrationRegistry {
    let all: [any Integration]

    init(_ integrations: [any Integration]) {
        self.all = integrations
    }

    static func makeDefault() -> IntegrationRegistry {
        IntegrationRegistry([
            SlackIntegration(),
            GoogleIntegration()
        ])
    }

    func integration(id: String) -> (any Integration)? {
        all.first { $0.id == id }
    }

    var connected: [any Integration] {
        all.filter { $0.connectionState.isConnected }
    }

    @discardableResult
    func routeCallback(_ url: URL) -> Bool {
        guard let id = url.pathComponents.last,
              let integration = integration(id: id) else {
            return false
        }

        return integration.handleCallback(url)
    }
}
