import Foundation
import Observation

@MainActor
@Observable
final class SlackConfig: IntegrationConfig {
    var persistenceKey: String { "slack" }

    var statusText: String { didSet { defaults.set(statusText, forKey: Keys.text) } }
    var statusEmoji: String { didSet { defaults.set(statusEmoji, forKey: Keys.emoji) } }
    var setPresenceAway: Bool { didSet { defaults.set(setPresenceAway, forKey: Keys.presence) } }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.statusText = defaults.string(forKey: Keys.text) ?? String(localized: "Out of Office")
        self.statusEmoji = defaults.string(forKey: Keys.emoji) ?? ":no_entry:"
        self.setPresenceAway = defaults.object(forKey: Keys.presence) as? Bool ?? true
    }

    private enum Keys {
        static let text = "slack.statusText"
        static let emoji = "slack.statusEmoji"
        static let presence = "slack.setPresenceAway"
    }
}
