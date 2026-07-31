import SwiftUI

struct SlackSettingsView: View {
    @Bindable var integration: SlackIntegration

    var body: some View {
        @Bindable var config = integration.slackConfig

        Form {
            Section("Connection") {
                IntegrationConnectionRow(integration: integration)
            }

            Section("Default status when away") {
                TextField("Status message", text: $config.statusText)
                TextField("Emoji (:shortcode:)", text: $config.statusEmoji)
                Toggle(isOn: $config.setPresenceAway) {
                    Text("Also set presence to Away")
                    Text("Flips your Slack presence, not just the status text")
                }
            }
            .disabled(!integration.connectionState.isConnected)
        }
        .formStyle(.grouped)
    }
}
