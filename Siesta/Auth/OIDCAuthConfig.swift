import Foundation

struct OIDCAuthConfig {
    var clientID: String
    var authorizationEndpoint: URL
    var tokenEndpoint: URL
    var scopes: [String]
    var redirectURI: URL
    var additionalParameters: [String: String] = [:]
}
