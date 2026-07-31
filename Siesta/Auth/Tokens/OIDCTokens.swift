import Foundation

struct OIDCTokens {
    var accessToken: String?
    var accessTokenExpiry: Date?
    var refreshToken: String?
    var raw: [String: Any]
}

protocol TokenResponseParser: Sendable {
    func parse(_ raw: [String: Any]) -> OIDCTokens
}

nonisolated struct StandardTokenParser: TokenResponseParser {
    func parse(_ raw: [String: Any]) -> OIDCTokens {
        let access = raw["access_token"] as? String
        let refresh = raw["refresh_token"] as? String
        let expiresIn = (raw["expires_in"] as? NSNumber)?.doubleValue
        let expiry = expiresIn.map { Date().addingTimeInterval($0) }

        return OIDCTokens(accessToken: access, accessTokenExpiry: expiry, refreshToken: refresh, raw: raw)
    }
}
