import Foundation
import Security
import os

struct RefreshTokenStore {
    private static let logger = Logger(category: "keychain")

    let account: String

    private let service = "dev.abgeo.siesta.oidc.refresh-token"

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true
        ]
    }

    func read() -> String? {
        var query = baseQuery
        var item: AnyObject?

        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            if status != errSecItemNotFound {
                Self.logger.error("read(\(account)) failed: \(status)")
            }

            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func save(_ token: String) {
        let data = Data(token.utf8)
        let update = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if update == errSecItemNotFound {
            var add = baseQuery
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

            let status = SecItemAdd(add as CFDictionary, nil)
            if status != errSecSuccess {
                Self.logger.error("add(\(account)) failed: \(status)")
            }
        } else if update != errSecSuccess {
            Self.logger.error("update(\(account)) failed: \(update)")
        }
    }

    func delete() {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Self.logger.error("delete(\(account)) failed: \(status)")
        }
    }
}
