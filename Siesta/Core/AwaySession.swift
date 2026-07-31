import Foundation

struct AwaySession: Equatable, Sendable, Codable {
    var startDate: Date
    var endDate: Date

    var duration: TimeInterval { endDate.timeIntervalSince(startDate) }
}
