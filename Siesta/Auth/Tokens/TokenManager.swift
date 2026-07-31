import Foundation

@MainActor
final class TokenManager {
    enum TokenError: LocalizedError {
        case notAuthenticated
        case noAccessToken
        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return String(localized: "Not authenticated.")
            case .noAccessToken: return String(localized: "Token response contained no access token.")
            }
        }
    }

    private let authenticator = OIDCAuthenticator()
    private let parser: any TokenResponseParser
    private let endpoint = TokenEndpointClient()
    private let cache = AccessTokenCache()
    private let store: RefreshTokenStore
    private let configProvider: @MainActor () -> OIDCAuthConfig

    init(
        integrationID: String,
        parser: any TokenResponseParser =
        StandardTokenParser(),
        config: @escaping @MainActor () -> OIDCAuthConfig
    ) {
        self.store = RefreshTokenStore(account: integrationID)
        self.parser = parser
        self.configProvider = config
    }

    var hasStoredCredentials: Bool { store.read() != nil }

    @discardableResult
    func connect() async throws -> OIDCTokens {
        let auth = try await authenticator.authorize(config: configProvider())
        return try await exchangeAuthorizationCode(auth.code, codeVerifier: auth.codeVerifier)
    }

    @discardableResult
    func resume(url: URL) -> Bool {
        authenticator.resume(url: url)
    }

    @discardableResult
    private func exchangeAuthorizationCode(_ code: String, codeVerifier: String?) async throws -> OIDCTokens {
        let raw = try await endpoint.requestTokens(
            config: configProvider(),
            grant: .authorizationCode(code: code, codeVerifier: codeVerifier)
        )
        let tokens = parser.parse(raw)

        persist(tokens)

        return tokens
    }

    func validAccessToken() async throws -> String {
        if let token = cache.validToken { return token }
        guard let refresh = store.read() else { throw TokenError.notAuthenticated }
        let raw = try await endpoint.requestTokens(config: configProvider(), grant: .refreshToken(refresh))
        let tokens = parser.parse(raw)

        persist(tokens)

        guard let access = tokens.accessToken else { throw TokenError.noAccessToken }
        return access
    }

    func clear() {
        cache.clear()
        store.delete()
    }

    private func persist(_ tokens: OIDCTokens) {
        if let access = tokens.accessToken {
            cache.set(access, expiry: tokens.accessTokenExpiry)
        }
        if let refresh = tokens.refreshToken {
            store.save(refresh)
        }
    }
}
