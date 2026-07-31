import Foundation
import Observation
import os

@MainActor
@Observable
final class SiestaController {
    private static let logger = Logger(category: "siesta")

    private(set) var session: AwaySession?
    /// Last run's per-integration outcome (id → error message, nil = success).
    private(set) var outcomes: [String: String?] = [:]
    /// The integrations selected for the running session, in display order.
    private(set) var participantIDs: [String] = []

    var isAway: Bool { session != nil }

    /// The connected integrations taking part in the running session.
    var participants: [any Integration] {
        participantIDs.compactMap { registry.integration(id: $0) }
    }

    private let registry: IntegrationRegistry
    private let sessionStore = AwaySessionStore()

    init(registry: IntegrationRegistry) {
        self.registry = registry
        if let snapshot = sessionStore.current {
            session = snapshot.session
            participantIDs = snapshot.participantIDs
            outcomes = snapshot.outcomes
        }
    }

    /// Begin an away session of the given duration, notifying only the selected
    /// integrations (`integrationIDs`, as chosen on the main screen). The session
    /// is set immediately so the UI flips to active; integration actions run in
    /// the background and record their outcomes.
    func start(duration: TimeInterval, integrationIDs: Set<String>) {
        let now = Date()
        session = AwaySession(startDate: now, endDate: now.addingTimeInterval(duration))
        outcomes = [:]
        participantIDs = registry.connected.map(\.id).filter { integrationIDs.contains($0) }
        guard let session else { return }
        persistSnapshot()

        for integration in participants {
            Task {
                do {
                    try await integration.startAway(session)
                    outcomes[integration.id] = .some(nil)
                    persistSnapshot()
                    Self.logger.info("\(integration.displayName) startAway ok")
                } catch {
                    outcomes[integration.id] = error.localizedDescription
                    persistSnapshot()
                    Self.logger.error("\(integration.displayName) startAway failed: \(error.localizedDescription)")
                }
            }
        }
    }

    /// End the current session and notify the integrations that took part.
    func stop() {
        session = nil
        outcomes = [:]
        let ending = participants
        participantIDs = []
        sessionStore.clear()

        for integration in ending {
            Task {
                do {
                    try await integration.stopAway()
                    Self.logger.info("\(integration.displayName) stopAway ok")
                } catch {
                    Self.logger.error("\(integration.displayName) stopAway failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func persistSnapshot() {
        guard let session else { return }
        sessionStore.save(AwaySessionStore.Snapshot(session: session, participantIDs: participantIDs, outcomes: outcomes))
    }
}
