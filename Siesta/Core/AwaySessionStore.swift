import Foundation

struct AwaySessionStore {
    struct Snapshot: Codable {
        let session: AwaySession
        let participantIDs: [String]
        let outcomes: [String: String?]
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var current: Snapshot? {
        guard let data = defaults.data(forKey: Keys.snapshot) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    func save(_ snapshot: Snapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Keys.snapshot)
    }

    func clear() {
        defaults.removeObject(forKey: Keys.snapshot)
    }

    private enum Keys {
        static let snapshot = "siesta.awaySession"
    }
}
