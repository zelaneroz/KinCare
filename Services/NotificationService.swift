import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let medicationSchedulingHorizonDays = 21
    private let maximumMedicationNotificationsPerTask = 48

    private init() {}

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleReminders(for task: CareTask) async throws {
        cancelReminders(for: task)

        guard task.reminderEnabled else { return }

        if task.category == .medication, !task.dosageReminders.isEmpty {
            try await scheduleMedicationReminders(for: task)
        } else {
            try await scheduleSingleTaskReminder(for: task)
        }
    }

    func refreshRemindersIfAuthorized(for tasks: [CareTask]) async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional else {
            return
        }

        for task in tasks where !task.isCompleted && task.reminderEnabled {
            try? await scheduleReminders(for: task)
        }
    }

    func cancelReminder(for task: CareTask) {
        cancelReminders(for: task)
    }

    func cancelReminders(for task: CareTask) {
        let identifiers = task.scheduledNotificationIdentifiers.isEmpty
            ? [task.notificationIdentifier]
            : task.scheduledNotificationIdentifiers

        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        task.scheduledNotificationIdentifiers = []
    }

    private func scheduleSingleTaskReminder(for task: CareTask) async throws {
        let fireDate = Calendar.current.date(
            byAdding: .minute,
            value: -task.reminderMinutesBefore,
            to: task.dueDate
        ) ?? task.dueDate

        guard fireDate > .now else { return }

        let content = notificationContent(for: task)
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: task.notificationIdentifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
        task.scheduledNotificationIdentifiers = [task.notificationIdentifier]
    }

    private func scheduleMedicationReminders(for task: CareTask) async throws {
        let calendar = Calendar.current
        let now = Date.now
        let horizonEnd = calendar.date(
            byAdding: .day,
            value: medicationSchedulingHorizonDays,
            to: now
        ) ?? now
        let planEnd = min(task.medicationEndDate ?? horizonEnd, horizonEnd)
        let planStart = max(task.medicationStartDate ?? now, now)

        var scheduledIdentifiers: [String] = []
        var occurrences: [(Date, MedicationDosageReminder)] = []

        for reminder in task.dosageReminders {
            occurrences.append(contentsOf: medicationOccurrences(
                for: reminder,
                start: planStart,
                end: planEnd,
                weeklyAnchor: task.medicationStartDate ?? task.dueDate
            ))
        }

        occurrences.sort { $0.0 < $1.0 }

        for (date, reminder) in occurrences.prefix(maximumMedicationNotificationsPerTask) {
            let timestamp = Int(date.timeIntervalSince1970)
            let identifier = "\(task.notificationIdentifier)-dose-\(reminder.id.uuidString)-\(timestamp)"
            let content = notificationContent(for: task, doseName: reminder.name)
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try await center.add(request)
            scheduledIdentifiers.append(identifier)
        }

        task.scheduledNotificationIdentifiers = scheduledIdentifiers
    }

    private func medicationOccurrences(
        for reminder: MedicationDosageReminder,
        start: Date,
        end: Date,
        weeklyAnchor: Date
    ) -> [(Date, MedicationDosageReminder)] {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: reminder.time)
        let anchorWeekday = calendar.component(.weekday, from: weeklyAnchor)
        var results: [(Date, MedicationDosageReminder)] = []
        var day = calendar.startOfDay(for: start)

        while day <= end {
            let weekday = calendar.component(.weekday, from: day)
            let shouldInclude: Bool

            switch reminder.frequency {
            case .daily:
                shouldInclude = true
            case .weekdays:
                shouldInclude = (2...6).contains(weekday)
            case .weekly:
                shouldInclude = weekday == anchorWeekday
            }

            if shouldInclude,
               let occurrence = calendar.date(
                    bySettingHour: time.hour ?? 9,
                    minute: time.minute ?? 0,
                    second: 0,
                    of: day
               ),
               occurrence >= start,
               occurrence <= end {
                results.append((occurrence, reminder))
            }

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: day) else {
                break
            }
            day = nextDay
        }

        return results
    }

    private func notificationContent(
        for task: CareTask,
        doseName: String? = nil
    ) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()

        if let doseName {
            content.title = task.medicationName.map { "\($0): \(doseName)" } ?? doseName
        } else {
            content.title = task.title
        }

        var bodyParts: [String] = []
        if let dosageAmount = task.dosageAmount,
           !dosageAmount.isEmpty,
           doseName != nil {
            bodyParts.append(dosageAmount)
        }

        if !task.notificationRecipientNames.isEmpty {
            bodyParts.append("For \(task.notificationRecipientNames.joined(separator: ", "))")
        } else if let assigned = task.assignedMemberName {
            bodyParts.append("Assigned to \(assigned)")
        }

        if doseName == nil {
            bodyParts.append("Due \(task.dueDate.formatted(date: .omitted, time: .shortened))")
        }

        content.body = bodyParts.isEmpty ? "KinCare reminder" : bodyParts.joined(separator: " • ")
        content.sound = .default
        content.userInfo = ["taskID": task.id.uuidString]
        return content
    }
}
