import SwiftUI
import Observation
import os

@MainActor
@Observable
final class GoogleIntegration: Integration {
    let id = "google"
    let displayName = String(localized: "Google Calendar")
    let iconSystemName = "calendar"

    var connectionState: ConnectionState = .disconnected
    let googleConfig = GoogleConfig()
    var config: any IntegrationConfig { googleConfig }

    @ObservationIgnored private let api = GoogleCalendarClient()
    @ObservationIgnored private let activeEvent = ActiveEventStore()
    @ObservationIgnored private let tokens = TokenManager(
        integrationID: "google",
        config: { GoogleIntegration.makeAuthConfig() }
    )

    init() {
        if tokens.hasStoredCredentials {
            connectionState = .connected(account: String(localized: "Google"))
        }
    }

    private static func makeAuthConfig() -> OIDCAuthConfig {
        OIDCAuthConfig(
            clientID: OIDCConfigStore.clientID(for: "google"),
            authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/auth")!,
            tokenEndpoint: URL(string: "https://oauth2.googleapis.com/token")!,
            scopes: [
                "https://www.googleapis.com/auth/calendar.events",
                "https://www.googleapis.com/auth/calendar.calendarlist.readonly"
            ],
            redirectURI: URL(string: "dev.abgeo.siesta:/auth/callback/google")!,
            additionalParameters: ["access_type": "offline", "prompt": "consent"]
        )
    }

    func connect() async {
        connectionState = .connecting
        do {
            let result = try await tokens.connect()
            connectionState = .connected(account: String(localized: "Google"))
            logger.info("connected (response keys: \(Array(result.raw.keys)))")
        } catch {
            connectionState = .disconnected
            logger.error("connect failed: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        tokens.clear()
        connectionState = .disconnected
    }

    @discardableResult
    func handleCallback(_ url: URL) -> Bool {
        tokens.resume(url: url)
    }

    func startAway(_ session: AwaySession) async throws {
        let token = try await tokens.validAccessToken()
        let eventID = try await api.createEvent(
            token: token,
            calendarID: googleConfig.calendarID,
            event: GoogleCalendarClient.EventDetails(
                summary: googleConfig.eventTitle,
                start: session.startDate,
                end: session.endDate,
                busy: googleConfig.showAs == .busy
            )
        )
        // Remember which event on which calendar, so `stopAway` can delete the
        // right one even if the configured calendar changes mid-session.
        activeEvent.save(id: eventID, calendarID: googleConfig.calendarID)
        logger.info("created event \(eventID) on '\(self.googleConfig.calendarID)' until \(session.endDate)")
    }

    func stopAway() async throws {
        guard let event = activeEvent.current else {
            logger.debug("no active event to remove")
            return
        }
        activeEvent.clear()

        let token = try await tokens.validAccessToken()
        do {
            try await api.deleteEvent(token: token, calendarID: event.calendarID, eventID: event.id)
            logger.info("removed event \(event.id)")
        } catch {

            logger.error("delete event \(event.id) failed: \(error.localizedDescription)")
        }
    }

    /// Calendars the signed-in account can create events on, for the settings
    /// picker. Excludes weaker access roles (`reader`, `freeBusyReader`) since
    /// `startAway`'s event-create call would fail on them.
    func fetchWritableCalendars() async throws -> [GoogleCalendarClient.CalendarListEntry] {
        let token = try await tokens.validAccessToken()
        let calendars = try await api.listCalendars(token: token)

        return calendars.filter { $0.accessRole == "owner" || $0.accessRole == "writer" }
    }

    func settingsView() -> AnyView {
        AnyView(GoogleSettingsView(integration: self))
    }
}

/// Persists the Siesta-created Calendar event (id + the calendar it lives on)
/// in `UserDefaults`, so an early "stop" can delete it, surviving an app
/// restart since the event outlives the process.
@MainActor
private struct ActiveEventStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var current: (id: String, calendarID: String)? {
        guard let id = defaults.string(forKey: Keys.id),
              let calendarID = defaults.string(forKey: Keys.calendar) else { return nil }

        return (id, calendarID)
    }

    func save(id: String, calendarID: String) {
        defaults.set(id, forKey: Keys.id)
        defaults.set(calendarID, forKey: Keys.calendar)
    }

    func clear() {
        defaults.removeObject(forKey: Keys.id)
        defaults.removeObject(forKey: Keys.calendar)
    }

    private enum Keys {
        static let id = "google.activeEventID"
        static let calendar = "google.activeEventCalendar"
    }
}
