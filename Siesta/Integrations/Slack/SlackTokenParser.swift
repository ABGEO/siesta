import Foundation

/// Slack's `oauth.v2.access` nests the user token under `authed_user` for the
/// authorization-code exchange, but returns it top-level for
/// `grant_type=refresh_token`, so both shapes need checking.
nonisolated struct SlackTokenParser: TokenResponseParser {
    func parse(_ raw: [String: Any]) -> OIDCTokens {
        let user = raw["authed_user"] as? [String: Any]
        let access = (user?["access_token"] as? String) ?? (raw["access_token"] as? String)
        let refresh = (user?["refresh_token"] as? String) ?? (raw["refresh_token"] as? String)
        let expiresIn = ((user?["expires_in"] as? NSNumber) ?? (raw["expires_in"] as? NSNumber))?.doubleValue
        let expiry = expiresIn.map { Date().addingTimeInterval($0) }

        return OIDCTokens(accessToken: access, accessTokenExpiry: expiry, refreshToken: refresh, raw: raw)
    }
}
