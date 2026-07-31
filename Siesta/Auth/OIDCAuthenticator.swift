import AppKit
import CryptoKit
import Security
import os

@MainActor
final class OIDCAuthenticator {
    private static let logger = Logger(category: "auth")

    struct AuthorizationResult {
        let code: String
        let codeVerifier: String?
    }

    enum AuthError: LocalizedError {
        case missingClientID
        case invalidRequest
        case browserUnavailable
        case noCode
        case stateMismatch
        case providerError(String)

        var errorDescription: String? {
            switch self {
            case .missingClientID: return String(localized: "Missing client ID. Add it to OIDCConfig.plist.")
            case .invalidRequest: return String(localized: "Could not build the authorization request.")
            case .browserUnavailable: return String(localized: "Could not open the browser to authorize.")
            case .noCode: return String(localized: "No authorization code was returned.")
            case .stateMismatch: return String(localized: "Authorization response did not match the request.")
            case let .providerError(message): return String(localized: "Authorization failed: \(message)")
            }
        }
    }

    private struct PendingRequest {
        let state: String
        let codeVerifier: String
        let continuation: CheckedContinuation<AuthorizationResult, Error>
    }

    private var pending: PendingRequest?

    func authorize(config: OIDCAuthConfig) async throws -> AuthorizationResult {
        guard !config.clientID.isEmpty else { throw AuthError.missingClientID }

        let state = Self.randomURLSafeToken()
        let codeVerifier = Self.randomURLSafeToken()
        let codeChallenge = Self.codeChallenge(for: codeVerifier)

        let url = try Self.authorizationURL(config: config, state: state, codeChallenge: codeChallenge)
        Self.logger.debug("Authorize URL: \(url.absoluteString)")

        return try await withCheckedThrowingContinuation { continuation in
            pending = PendingRequest(state: state, codeVerifier: codeVerifier, continuation: continuation)
            guard NSWorkspace.shared.open(url) else {
                pending = nil
                continuation.resume(throwing: AuthError.browserUnavailable)
                return
            }
        }
    }

    private static func authorizationURL(config: OIDCAuthConfig, state: String, codeChallenge: String) throws -> URL {
        guard var components = URLComponents(url: config.authorizationEndpoint, resolvingAgainstBaseURL: false) else {
            throw AuthError.invalidRequest
        }

        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI.absoluteString),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        if !config.scopes.isEmpty {
            queryItems.append(URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")))
        }

        queryItems += config.additionalParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = queryItems

        guard let url = components.url else { throw AuthError.invalidRequest }

        return url
    }

    @discardableResult
    func resume(url: URL) -> Bool {
        guard let pending else { return false }
        self.pending = nil

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        if let error = value("error") {
            pending.continuation.resume(throwing: AuthError.providerError(value("error_description") ?? error))
        } else if value("state") != pending.state {
            pending.continuation.resume(throwing: AuthError.stateMismatch)
        } else if let code = value("code") {
            pending.continuation.resume(returning: AuthorizationResult(code: code, codeVerifier: pending.codeVerifier))
        } else {
            pending.continuation.resume(throwing: AuthError.noCode)
        }

        return true
    }

    // MARK: - PKCE (RFC 7636)

    private static func randomURLSafeToken(byteCount: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        return base64URLEncode(Data(bytes))
    }

    private static func codeChallenge(for verifier: String) -> String {
        base64URLEncode(Data(SHA256.hash(data: Data(verifier.utf8))))
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
