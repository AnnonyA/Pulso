import SwiftUI

@main
struct PulsoApp: App {
    @State private var store = ReaderStore()
    @AppStorage("pulso.appearance") private var appearance = AppAppearance.system.rawValue
    @Environment(\.scenePhase) private var scenePhase

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
