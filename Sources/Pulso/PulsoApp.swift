import SwiftUI

@main
struct PulsoApp: App {
    @State private var store = ReaderStore()
    @AppStorage("pulso.appearance") private var appearance = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-pulso-ui-testing") {
            // Let simctl control light/dark UI tests. This never changes NFC
            // availability, card records, or the release app's launch behavior.
            UserDefaults.standard.removeObject(forKey: "pulso.appearance")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(PulsoTheme.accent)
                .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
                .onChange(of: scenePhase) { _, phase in
                    // The system NFC sheet can make the app inactive. Only backgrounding cancels.
                    if phase == .background {
                        store.cancelScan()
                    }
                }
        }
    }
}
