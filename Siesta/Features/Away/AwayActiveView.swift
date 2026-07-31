import SwiftUI

/// The popover's state while an away session is running.
struct AwayActiveView: View {
    @Environment(SiestaController.self) private var siesta

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PopoverHeader(title: "You're away", dotColor: .orange)

            if let session = siesta.session {
                countdown(for: session)
            }

            if !siesta.participants.isEmpty {
                chips
            }

            Button(role: .destructive) {
                siesta.stop()
            } label: {
                Text("Return now").frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.bordered)
        }
        .padding(16)
        .frame(width: 300)
    }

    private func countdown(for session: AwaySession) -> some View {
        VStack(spacing: 2) {
            Text("Time remaining")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(Away.remaining(until: session.endDate, now: context.date))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Text("Back at \(Away.clockTime(session.endDate))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var chips: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                ForEach(siesta.participants, id: \.id) { integration in
                    ServiceChip(
                        title: integration.displayName,
                        systemImage: errorMessage(for: integration) == nil ? "checkmark" : "xmark",
                        active: errorMessage(for: integration) == nil
                    )
                }
            }
            ForEach(siesta.participants, id: \.id) { integration in
                if let error = errorMessage(for: integration) {
                    Text("\(integration.displayName): \(error)")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }
        }
    }

    private func errorMessage(for integration: any Integration) -> String? {
        if case let .some(.some(message)) = siesta.outcomes[integration.id] {
            return message
        }
        return nil
    }
}

#Preview {
    let slack = SlackIntegration()
    slack.connectionState = .connected(account: "Slack")
    let registry = IntegrationRegistry([slack])
    let controller = SiestaController(registry: registry)
    controller.start(duration: 3600, integrationIDs: [slack.id])

    return AwayActiveView()
        .environment(controller)
        .environment(registry)
}
