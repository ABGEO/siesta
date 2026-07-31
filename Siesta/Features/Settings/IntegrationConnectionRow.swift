import SwiftUI

struct IntegrationConnectionRow: View {
    let integration: any Integration

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: integration.iconSystemName)
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text(integration.displayName)
                    .font(.body.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            switch integration.connectionState {
            case .connecting:
                ProgressView().controlSize(.small)
            case .connected:
                Button("Disconnect", role: .destructive) {
                    Task { await integration.disconnect() }
                }
            case .disconnected:
                Button("Connect…") {
                    Task { await integration.connect() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 2)
    }

    private var detail: String {
        switch integration.connectionState {
        case let .connected(account): return account
        case .connecting: return String(localized: "Connecting…")
        case .disconnected: return String(localized: "Not connected")
        }
    }
}
