import SwiftUI
import SwiftData

struct KinCareInvite: Equatable {
    let code: String
    let recipientName: String

    init?(url: URL) {
        guard let components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        let isKinCareScheme = components.scheme?.lowercased() == "kincare"
        let isWebInvite = components.path.lowercased().contains("/join")
        let isCustomInvite = components.host?.lowercased() == "join"

        guard isKinCareScheme || isWebInvite || isCustomInvite else {
            return nil
        }

        let items = components.queryItems ?? []
        guard let rawCode = items.first(where: { $0.name == "code" })?.value else {
            return nil
        }

        let normalizedCode = rawCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalizedCode.isEmpty else {
            return nil
        }

        self.code = normalizedCode
        self.recipientName = items
            .first(where: { $0.name == "person" })?
            .value?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \UserProfile.createdAt)
    private var profiles: [UserProfile]

    @State private var pendingInvite: KinCareInvite?
    @State private var didRefreshReminders = false

    var body: some View {
        Group {
            if let profile = profiles.first, profile.isOnboardingComplete {
                RootTabView()
                    .task {
                        guard !didRefreshReminders else { return }
                        didRefreshReminders = true

                        if let tasks = try? modelContext.fetch(
                            FetchDescriptor<CareTask>()
                        ) {
                            await NotificationService.shared
                                .refreshRemindersIfAuthorized(for: tasks)
                            try? modelContext.save()
                        }
                    }
            } else {
                OnboardingFlowView(prefilledInvite: pendingInvite)
                    .id(pendingInvite?.code ?? "fresh-onboarding")
            }
        }
        .onOpenURL { url in
            pendingInvite = KinCareInvite(url: url)
        }
    }
}
