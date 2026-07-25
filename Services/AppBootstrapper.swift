import Foundation
import SwiftData

enum AppBootstrapper {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        do {
            let existingTasks = try context.fetch(FetchDescriptor<CareTask>())
            guard existingTasks.isEmpty else { return }

            let recipient = CareRecipient(
                firstName: "Mom",
                relationship: "Mother",
                careNotes: "Prefers morning appointments."
            )

            let you = CareMember(
                name: "You",
                role: .caregiver,
                isAvailable: true,
                availabilityNote: "Primary coordinator"
            )

            let alex = CareMember(
                name: "Alex",
                role: .supporter,
                isAvailable: true,
                availabilityNote: "Available Thursday evenings",
                preferredCategories: [.meal, .transportation]
            )

            let maya = CareMember(
                name: "Maya",
                role: .supporter,
                isAvailable: true,
                availabilityNote: "Available on weekends",
                preferredCategories: [.companionship, .household]
            )

            let calendar = Calendar.current
            let medicationTime = calendar.date(
                bySettingHour: 18,
                minute: 0,
                second: 0,
                of: .now
            ) ?? .now

            let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
            let appointmentTime = calendar.date(
                bySettingHour: 10,
                minute: 30,
                second: 0,
                of: tomorrow
            ) ?? tomorrow

            context.insert(recipient)
            context.insert(you)
            context.insert(alex)
            context.insert(maya)

            context.insert(
                CareTask(
                    title: "Evening medication",
                    taskNotes: "Confirm after it is taken.",
                    dueDate: medicationTime,
                    category: .medication,
                    assignedMemberName: "You",
                    reminderEnabled: true,
                    reminderMinutesBefore: 15
                )
            )

            context.insert(
                CareTask(
                    title: "Primary care appointment",
                    taskNotes: "Bring medication list.",
                    dueDate: appointmentTime,
                    category: .appointment,
                    assignedMemberName: "Alex",
                    reminderEnabled: true,
                    reminderMinutesBefore: 60
                )
            )

            try context.save()
        } catch {
            assertionFailure("Unable to seed KinCare sample data: \(error)")
        }
    }
}
