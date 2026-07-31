import Foundation
import Observation

enum ShowAs: String, CaseIterable, Identifiable {
    case busy = "Busy"
    case free = "Free"
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .busy: return String(localized: "Busy")
        case .free: return String(localized: "Free")
        }
    }
}

@MainActor
@Observable
final class GoogleConfig: IntegrationConfig {
    var persistenceKey: String { "google" }

    var eventTitle: String { didSet { defaults.set(eventTitle, forKey: Keys.title) } }
    var calendarID: String { didSet { defaults.set(calendarID, forKey: Keys.calendar) } }
    var showAs: ShowAs {
        didSet { defaults.set(showAs.rawValue, forKey: Keys.showAs) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.eventTitle = defaults.string(forKey: Keys.title) ?? String(localized: "Out of Office")
        self.calendarID = defaults.string(forKey: Keys.calendar) ?? "primary"
        self.showAs = defaults.string(forKey: Keys.showAs).flatMap(ShowAs.init) ?? .busy
    }

    private enum Keys {
        static let title = "google.eventTitle"
        static let calendar = "google.calendarID"
        static let showAs = "google.showAs"
    }
}
