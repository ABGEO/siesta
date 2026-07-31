import Alamofire
import Foundation

struct GoogleCalendarClient {
    enum APIError: LocalizedError {
        case api(String)
        var errorDescription: String? {
            switch self {
            case let .api(message): return String(localized: "Google Calendar API error: \(message)")
            }
        }
    }

    private let session: Session
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(session: Session = .default) {
        self.session = session
    }

    nonisolated struct EventDetails {
        let summary: String
        let start: Date
        let end: Date
        let busy: Bool
    }

    func createEvent(token: String, calendarID: String, event: EventDetails) async throws -> String {
        let body: [String: Any] = [
            "summary": event.summary,
            "start": ["dateTime": dateFormatter.string(from: event.start)],
            "end": ["dateTime": dateFormatter.string(from: event.end)],
            "transparency": event.busy ? "opaque" : "transparent"
        ]
        let data = try await send(
            eventsURL(calendarID: calendarID),
            method: .post,
            token: token,
            body: body
        )

        do {
            return try JSONDecoder().decode(CreatedEvent.self, from: data).id
        } catch {
            throw APIError.api(String(localized: "Unexpected create-event response."))
        }
    }

    func deleteEvent(token: String, calendarID: String, eventID: String) async throws {
        _ = try await send(
            "\(eventsURL(calendarID: calendarID))/\(escape(eventID))",
            method: .delete,
            token: token,
            body: nil
        )
    }

    func listCalendars(token: String) async throws -> [CalendarListEntry] {
        let data = try await send(
            "https://www.googleapis.com/calendar/v3/users/me/calendarList",
            method: .get,
            token: token,
            body: nil
        )

        do {
            return try JSONDecoder().decode(CalendarListResponse.self, from: data).items
        } catch {
            throw APIError.api(String(localized: "Unexpected calendar-list response."))
        }
    }

    private func eventsURL(calendarID: String) -> String {
        "https://www.googleapis.com/calendar/v3/calendars/\(escape(calendarID))/events"
    }

    private func escape(_ segment: String) -> String {
        segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? segment
    }

    private func send(
        _ url: String,
        method: HTTPMethod,
        token: String,
        body: [String: Any]?
    ) async throws -> Data {
        let response = await session.request(
            url,
            method: method,
            parameters: body,
            encoding: JSONEncoding.default,
            headers: [.authorization(bearerToken: token)]
        )
        .serializingData(emptyResponseCodes: [200, 204, 205])
        .response

        let data: Data
        do {
            data = try response.result.get()
        } catch {
            throw APIError.api(error.localizedDescription)
        }

        guard let status = response.response?.statusCode else {
            throw APIError.api(String(localized: "No HTTP response."))
        }
        guard (200..<300).contains(status) else {
            let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error.message
            throw APIError.api(message ?? String(localized: "HTTP \(status)"))
        }

        return data
    }

    private nonisolated struct CreatedEvent: Decodable {
        let id: String
    }

    private nonisolated struct ErrorDetail: Decodable {
        let message: String
    }

    private nonisolated struct ErrorEnvelope: Decodable {
        let error: ErrorDetail
    }

    nonisolated struct CalendarListEntry: Decodable {
        let id: String
        let summary: String
        let primary: Bool?
        let accessRole: String
    }

    private nonisolated struct CalendarListResponse: Decodable {
        let items: [CalendarListEntry]
    }
}
