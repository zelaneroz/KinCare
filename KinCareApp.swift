import SwiftUI
import SwiftData

@main
struct KinCareApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.light)
                .tint(KinCareTheme.sage)
                .kinCarePageStyle()
        }
        .modelContainer(
            for: [
                CareTask.self,
                CareMember.self,
                CareRecipient.self,
                CapacityCheckIn.self,
                UserProfile.self,
                CareCrew.self
            ]
        )
    }
}
