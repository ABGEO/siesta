import Alamofire
import Foundation

struct SlackAPIClient {
    enum APIError: LocalizedError {
        case notOK(String)
        var errorDescription: String? {
            switch self {
            case let .notOK(error): return String(localized: "Slack API error: \(error)")
            }
        }
    }

    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func setStatus(token: String, text: String, emoji: String, until: Date) async throws {
        try await post(
            method: "users.profile.set",
            token: token,
            body: ["profile": [
                "status_text": text,
                "status_emoji": emoji,
                "status_expiration": Int(until.timeIntervalSince1970)
            ]]
        )
    }

    func clearStatus(token: String) async throws {
        try await post(
            method: "users.profile.set",
            token: token,
            body: ["profile": ["status_text": "", "status_emoji": "", "status_expiration": 0]]
        )
    }

    func setPresence(token: String, away: Bool) async throws {
        try await post(
            method: "users.setPresence",
            token: token,
            body: ["presence": away ? "away" : "auto"]
        )
    }

    private nonisolated struct Response: Decodable {
        let ok: Bool
        let error: String?
    }

    private func post(method: String, token: String, body: [String: Any]) async throws {
        let response = try await session.request(
            "https://slack.com/api/\(method)",
            method: .post,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: [.authorization(bearerToken: token)]
        )
            .validate()
            .serializingDecodable(Response.self)
            .value

        if !response.ok {
            throw APIError.notOK(response.error ?? String(localized: "unknown"))
        }
    }
}
