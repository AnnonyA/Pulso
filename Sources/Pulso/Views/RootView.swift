import SwiftUI

struct RootView: View {
    @AppStorage("pulso.hasSeenOnboarding") private var hasSeenOnboarding = false

    private var skipsOnboardingForUITests: Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-pulso-ui-testing") && arguments.contains("-pulso-skip-onboarding")
        #else
        return false
        #endif
    }

    var body: some View {
        NavigationStack {
            DashboardView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding && !skipsOnboardingForUITests },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView {
                hasSeenOnboarding = true
            }
            .interactiveDismissDisabled()
        }
    }
}
