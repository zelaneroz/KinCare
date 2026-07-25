import EventKit
import Foundation

enum CalendarServiceError: LocalizedError {
    case accessDenied
    case noDefaultCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "KinCare does not have permission to add this event. Enable Calendar access in Settings."
        case .noDefaultCalendar:
            return "No writable default calendar is available."
        }
    }
}

@MainActor
final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    private init() {}

    func addOrUpdateCalendarEvent(for task: CareTask) async throws -> String {
        let granted = try await eventStore.requestWriteOnlyAccessToEvents()
        guard granted else { throw CalendarServiceError.accessDenied }

        if let identifier = task.calendarEventIdentifier {
            if let existingEvent = eventStore.event(withIdentifier: identifier) {
                configure(existingEvent, using: task)
                let hasRecurrence = existingEvent.recurrenceRules?.isEmpty == false
                let span: EKSpan = hasRecurrence ? .futureEvents : .thisEvent
                try eventStore.save(existingEvent, span: span)
            }

            // With write-only access, EventKit may not return an existing event for editing.
            // Keep the stored identifier rather than creating a duplicate calendar event.
            return identifier
        }

        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            throw CalendarServiceError.noDefaultCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        configure(event, using: task)
        try eventStore.save(event, span: .thisEvent)
        return event.eventIdentifier
    }

    private func configure(_ event: EKEvent, using task: CareTask) {
        event.title = task.title
        event.notes = task.calendarNotes
        event.startDate = task.dueDate
        event.endDate = Calendar.current.date(
            byAdding: .minute,
            value: 30,
            to: task.dueDate
        ) ?? task.dueDate

        for rule in event.recurrenceRules ?? [] {
            event.removeRecurrenceRule(rule)
        }

        guard let frequency = eventKitFrequency(for: task.repeatFrequency) else {
            return
        }

        let recurrenceEnd = task.repeatEndDate.map { EKRecurrenceEnd(end: $0) }
        let rule = EKRecurrenceRule(
            recurrenceWith: frequency,
            interval: 1,
            end: recurrenceEnd
        )
        event.addRecurrenceRule(rule)
    }

    private func eventKitFrequency(
        for frequency: TaskRepeatFrequency
    ) -> EKRecurrenceFrequency? {
        switch frequency {
        case .never: return nil
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }
}
