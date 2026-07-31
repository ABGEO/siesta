import Foundation
import os

enum OIDCConfigStore {
    private static let logger = Logger(category: "auth")

    private static let config: [String: [String: String]] = {
        guard
            let url = Bundle.main.url(forResource: "OIDCConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dict = plist as? [String: [String: String]]
        else {
            logger.error("OIDCConfig.plist missing or malformed.")
            return [:]
        }

        return dict
    }()

    static func clientID(for provider: String) -> String {
        config[provider]?["clientID"] ?? ""
    }
}
