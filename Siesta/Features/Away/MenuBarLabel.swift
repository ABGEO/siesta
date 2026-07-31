import SwiftUI

/// The icon (and optional countdown) shown in the menu bar itself.
struct MenuBarLabel: View {
    @Environment(SiestaController.self) private var siesta
    @Environment(AppSettings.self) private var settings

    var body: some View {
        if let session = siesta.session {
            if settings.showCountdownInMenuBar {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Label(
                        Away.remaining(until: session.endDate, now: context.date),
                        systemImage: "moon.zzz.fill"
                    )
                }
            } else {
                Image(systemName: "moon.zzz.fill")
            }
        } else {
            Image(systemName: "cup.and.saucer.fill")
        }
    }
}

#Preview("Idle") {
    let registry = IntegrationRegistry([])
    return MenuBarLabel()
        .environment(SiestaController(registry: registry))
        .environment(AppSettings())
        .padding()
}

#Preview("Away · countdown") {
    let registry = IntegrationRegistry([])
    let controller = SiestaController(registry: registry)
    controller.start(duration: 3600, integrationIDs: [])
    let settings = AppSettings()
    settings.showCountdownInMenuBar = true

    return MenuBarLabel()
        .environment(controller)
        .environment(settings)
        .padding()
}
