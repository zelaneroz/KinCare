import SwiftUI

@main
struct KinCareApp: App {
    @State private var didOnboard = false

    var body: some Scene {
        WindowGroup {
            if didOnboard {
                MainTabView()
            } else {
                OnboardingFlow(onFinished: { didOnboard = true })
            }
        }
    }
}
