import AppIntents

struct OpenKinCareTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Open KinCare Today"
    static var description = IntentDescription(
        "Opens KinCare to the caregiver's Today view."
    )
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct KinCareShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenKinCareTodayIntent(),
            phrases: [
                "Open \(.applicationName) today",
                "Show my care plan in \(.applicationName)"
            ],
            shortTitle: "Open Care Plan",
            systemImageName: "heart.text.clipboard"
        )
    }
}
