import SwiftUI

struct RootView: View {
    @AppStorage("pulso.hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        TabView {
            Tab("Tarjeta", systemImage: "wave.3.right") {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab("Lecturas", systemImage: "clock.arrow.circlepath") {
                NavigationStack {
                    HistoryView()
                }
            }
            Tab("Ajustes", systemImage: "slider.horizontal.3") {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabBarMinimizeBehavior(.never)
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView {
                hasSeenOnboarding = true
            }
            .interactiveDismissDisabled()
        }
    }
}
