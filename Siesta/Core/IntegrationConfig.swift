import Foundation

@MainActor
protocol IntegrationConfig: AnyObject {
    var persistenceKey: String { get }
}
