import SwiftUI

struct GeneralSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                Toggle(isOn: $settings.showCountdownInMenuBar) {
                    Text("Show countdown in menu bar")
                    Text("Display remaining time next to the icon")
                }
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    GeneralSettingsView()
        .environment(AppSettings())
        .frame(width: 460)
}
