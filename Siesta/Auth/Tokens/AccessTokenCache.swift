import Foundation

@MainActor
final class AccessTokenCache {
    private var token: String?
    private var expiry: Date?

    var validToken: String? {
        guard let token else { return nil }
        guard let expiry else { return token }
        guard expiry > Date().addingTimeInterval(60) else { return nil }

        return token
    }

    func set(_ token: String, expiry: Date?) {
        self.token = token
        self.expiry = expiry
    }

    func clear() {
        token = nil
        expiry = nil
    }
}
