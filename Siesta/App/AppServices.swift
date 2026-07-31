import Foundation

@MainActor
final class AppServices {
    static let shared = AppServices()

    let registry: IntegrationRegistry
    let controller: SiestaController
    let settings = AppSettings()

    private init() {
        let registry = IntegrationRegistry.makeDefault()

        self.registry = registry
        self.controller = SiestaController(registry: registry)
    }
}
