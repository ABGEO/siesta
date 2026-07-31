import SwiftUI

struct SettingsView: View {
    @Environment(IntegrationRegistry.self) private var registry

    @State private var selectedTab = "general"

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .navigationTitle("Settings")
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag("general")

            ForEach(registry.all, id: \.id) { integration in
                integration.settingsView()
                    .navigationTitle("Settings")
                    .tabItem { Label(integration.displayName, systemImage: integration.iconSystemName) }
                    .tag(integration.id)
            }

            InfoSettingsView()
                .navigationTitle("Settings")
                .tabItem { Label("Info", systemImage: "info.circle") }
                .tag("info")
        }
        .frame(width: 460)
        .frame(minHeight: 320)
        .onReceive(NotificationCenter.default.publisher(for: .siestaOpenSettings)) { _ in
            selectedTab = "general"
        }
    }
}

#Preview {
    SettingsView()
        .environment(IntegrationRegistry.makeDefault())
        .environment(AppSettings())
}
