import SwiftUI

struct ContentView: View {
    @Environment(SiestaController.self) private var siesta

    var body: some View {
        if siesta.isAway {
            AwayActiveView()
        } else {
            AwayIdleView()
        }
    }
}

#Preview {
    let registry = IntegrationRegistry([])
    return ContentView()
        .environment(SiestaController(registry: registry))
        .environment(registry)
}
