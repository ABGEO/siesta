import SwiftUI
import Observation
import os

@MainActor
@Observable
final class SlackIntegration: Integration {
    let id = "slack"
    let displayName = String(localized: "Slack")
    let iconSystemName = "message.fill"

    var connectionState: ConnectionState = .disconnected
    let slackConfig = SlackConfig()
    var config: any IntegrationConfig { slackConfig }

    @ObservationIgnored private let api = SlackAPIClient()
    @ObservationIgnored private let tokens = TokenManager(
        integrationID: "slack",
        parser: SlackTokenParser(),
        config: { SlackIntegration.makeAuthConfig() }
    )

    init() {
        if tokens.hasStoredCredentials {
            connectionState = .connected(account: String(localized: "Slack"))
        }
    }

    private static func makeAuthConfig() -> OIDCAuthConfig {
        OIDCAuthConfig(
            clientID: OIDCConfigStore.clientID(for: "slack"),
            authorizationEndpoint: URL(string: "https://slack.com/oauth/v2/authorize")!,
            tokenEndpoint: URL(string: "https://slack.com/api/oauth.v2.access")!,
            scopes: [],
            redirectURI: URL(string: "dev.abgeo.siesta://auth/callback/slack")!,
            additionalParameters: ["user_scope": "users.profile:write,users:write"]
        )
    }

    func connect() async {
        connectionState = .connecting
        do {
            let result = try await tokens.connect()
            let team = (result.raw["team"] as? [String: Any])?["name"] as? String
            connectionState = .connected(account: team ?? String(localized: "Slack"))
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
        try await api.setStatus(
            token: token,
            text: slackConfig.statusText,
            emoji: slackConfig.statusEmoji,
            until: session.endDate
        )

        if slackConfig.setPresenceAway {
            try await api.setPresence(token: token, away: true)
        }
    }

    func stopAway() async throws {
        let token = try await tokens.validAccessToken()
        try await api.clearStatus(token: token)

        if slackConfig.setPresenceAway {
            try await api.setPresence(token: token, away: false)
        }
    }

    func settingsView() -> AnyView {
        AnyView(SlackSettingsView(integration: self))
    }
}
