import SwiftUI

/// The popover's default state: pick a duration, choose which connected services
/// to update (tap a chip to include/exclude it), and go away. The message each
/// service applies is configured in Settings.
struct AwayIdleView: View {
    @Environment(SiestaController.self) private var siesta
    @Environment(IntegrationRegistry.self) private var registry

    private enum Selection: Equatable {
        case minutes(Int)
        case untilTomorrow
        case custom
    }

    @State private var selection: Selection = .minutes(60)
    @State private var customHours = 1
    @State private var customMinutes = 0
    /// Connected integrations included in the next away session. Seeded to all
    /// connected; tapping a chip toggles membership.
    @State private var enabledIDs: Set<String> = []
    /// Integrations already reconciled by `syncEnabled`, so a service the user
    /// turned off isn't re-enabled just because the view reappears.
    @State private var knownIDs: Set<String> = []

    private let presets = [30, 60, 120]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PopoverHeader(title: "Siesta", dotColor: .green)

            sectionLabel("Away for")
            presetGrid
            if selection == .custom {
                customPicker
            }

            if registry.connected.isEmpty {
                Text("No integrations connected. Siesta will run a local timer only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                sectionLabel("Update status on")
                serviceChips
            }

            Button {
                siesta.start(duration: resolvedDuration, integrationIDs: enabledIDs)
            } label: {
                Text("Set Away · \(Away.durationLabel(resolvedDuration))")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(resolvedDuration <= 0)
        }
        .padding(16)
        .frame(width: 300)
        .onAppear(perform: syncEnabled)
        .onChange(of: connectedIDs) { _, _ in syncEnabled() }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
    }

    // MARK: Service selection

    private var serviceChips: some View {
        FlowLayout(spacing: 6) {
            ForEach(registry.connected, id: \.id) { integration in
                let isOn = enabledIDs.contains(integration.id)
                Button {
                    toggle(integration.id)
                } label: {
                    ServiceChip(
                        title: integration.displayName,
                        systemImage: integration.iconSystemName,
                        active: isOn
                    )
                }
                .buttonStyle(.plain)
                .help(isOn ? "Click to skip \(integration.displayName)" : "Click to include \(integration.displayName)")
            }
        }
    }

    private func toggle(_ id: String) {
        if enabledIDs.contains(id) {
            enabledIDs.remove(id)
        } else {
            enabledIDs.insert(id)
        }
    }

    /// Keep the selection in sync with the connected set: newly connected
    /// integrations default to on; disconnected ones drop out. A service the
    /// user deliberately turned off stays off.
    private func syncEnabled() {
        let connected = Set(connectedIDs)
        let newlyConnected = connected.subtracting(knownIDs)

        enabledIDs.formUnion(newlyConnected)      // default new services on
        enabledIDs.formIntersection(connected)    // drop disconnected ones
        knownIDs = connected
    }

    private var connectedIDs: [String] { registry.connected.map(\.id) }

    // MARK: Duration selection

    private var presetGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { minutes in
                    presetButton(
                        title: Away.durationLabel(TimeInterval(minutes * 60)),
                        isOn: selection == .minutes(minutes)
                    ) { selection = .minutes(minutes) }
                }
            }
            HStack(spacing: 8) {
                presetButton(title: "Until tomorrow", isOn: selection == .untilTomorrow, prominent: false) {
                    selection = .untilTomorrow
                }
                presetButton(title: "Custom", isOn: selection == .custom, prominent: false) {
                    selection = .custom
                }
            }
        }
    }

    private func presetButton(
        title: String,
        isOn: Bool,
        prominent: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .buttonStyle(.plain)
        .background(
            isOn ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary.opacity(0.6)),
            in: .rect(cornerRadius: 9)
        )
        .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(prominent ? .primary : .secondary))
    }

    private var customPicker: some View {
        HStack {
            Stepper(value: $customHours, in: 0...23) {
                Text("\(customHours) h").monospacedDigit()
            }
            Stepper(value: $customMinutes, in: 0...59, step: 5) {
                Text("\(customMinutes) m").monospacedDigit()
            }
        }
        .font(.callout)
    }

    private var resolvedDuration: TimeInterval {
        switch selection {
        case let .minutes(minutes):
            return TimeInterval(minutes * 60)
        case .untilTomorrow:
            return max(0, Away.untilTomorrow().timeIntervalSinceNow)
        case .custom:
            return TimeInterval((customHours * 60 + customMinutes) * 60)
        }
    }
}

#Preview {
    let registry = IntegrationRegistry([])
    return AwayIdleView()
        .environment(SiestaController(registry: registry))
        .environment(registry)
}
