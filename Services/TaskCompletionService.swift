import Foundation
import SwiftData

@MainActor
enum TaskCompletionService {
    static func toggle(
        _ task: CareTask,
        among allTasks: [CareTask],
        in context: ModelContext
    ) async {
        if task.isCompleted {
            task.isCompleted = false
            task.completedAt = nil
            task.completedByName = nil

            let granted = try? await NotificationService.shared.requestAuthorization()
            if granted == true {
                try? await NotificationService.shared.scheduleReminders(for: task)
            }
        } else {
            task.isCompleted = true
            task.completedAt = .now
            task.completedByName = "You"
            NotificationService.shared.cancelReminders(for: task)

            if task.category != .medication,
               let nextDate = task.nextOccurrenceDate(),
               !alreadyHasOccurrence(
                    for: task,
                    on: nextDate,
                    among: allTasks
               ) {
                let nextTask = task.copyForNextOccurrence(on: nextDate)
                context.insert(nextTask)

                let granted = try? await NotificationService.shared.requestAuthorization()
                if granted == true {
                    try? await NotificationService.shared.scheduleReminders(for: nextTask)
                }
            }
        }

        try? context.save()
    }

    private static func alreadyHasOccurrence(
        for task: CareTask,
        on date: Date,
        among allTasks: [CareTask]
    ) -> Bool {
        let series = task.seriesIdentifier ?? task.id
        return allTasks.contains { candidate in
            (candidate.seriesIdentifier ?? candidate.id) == series &&
            abs(candidate.dueDate.timeIntervalSince(date)) < 60
        }
    }
}
