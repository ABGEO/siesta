import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(account: String)

    var isConnected: Bool {
        if case .connected = self { return true }

        return false
    }

    var accountLabel: String? {
        if case let .connected(account) = self { return account }

        return nil
    }
}
