import Alamofire
import Foundation

struct TokenEndpointClient {
    enum Grant {
        case authorizationCode(code: String, codeVerifier: String?)
        case refreshToken(String)
    }

    enum TokenEndpointError: LocalizedError {
        case badResponse
        var errorDescription: String? { String(localized: "Unexpected token-endpoint response.") }
    }

    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func requestTokens(config: OIDCAuthConfig, grant: Grant) async throws -> [String: Any] {
        var params: [String: String] = ["client_id": config.clientID]
        switch grant {
        case let .authorizationCode(code, codeVerifier):
            params["grant_type"] = "authorization_code"
            params["code"] = code
            params["redirect_uri"] = config.redirectURI.absoluteString
            if let codeVerifier { params["code_verifier"] = codeVerifier }
        case let .refreshToken(token):
            params["grant_type"] = "refresh_token"
            params["refresh_token"] = token
        }

        let data = try await session.request(
            config.tokenEndpoint,
            method: .post,
            parameters: params,
            encoding: URLEncoding(destination: .httpBody)
        )
        .serializingData()
        .value

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TokenEndpointError.badResponse
        }
        return json
    }
}
