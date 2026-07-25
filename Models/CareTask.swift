import Foundation
import SwiftData

enum CareTaskCategory: String, CaseIterable, Codable, Identifiable {
    case medication
    case appointment
    case meal
    case personalCare
    case transportation
    case household
    case companionship
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .medication: return "Medication"
        case .appointment: return "Appointment"
        case .meal: return "Meal"
        case .personalCare: return "Personal Care"
        case .transportation: return "Transportation"
        case .household: return "Household"
        case .companionship: return "Companionship"
        case .other: return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .medication: return "pills"
        case .appointment: return "calendar"
        case .meal: return "fork.knife"
        case .personalCare: return "heart"
        case .transportation: return "car"
        case .household: return "house"
        case .companionship: return "person.2"
        case .other: return "checkmark.circle"
        }
    }
}

enum TaskRepeatFrequency: String, CaseIterable, Codable, Identifiable {
    case never
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .never: return "Never"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .never:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
}

enum CareTaskVisibility: String, CaseIterable, Codable, Identifiable {
    case careCircle
    case caregiversOnly
    case onlyMe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .careCircle: return "Everyone in the care circle"
        case .caregiversOnly: return "Caregivers only"
        case .onlyMe: return "Only me"
        }
    }
}

enum MedicationType: String, CaseIterable, Codable, Identifiable {
    case tablet
    case capsule
    case liquid
    case injection
    case patch
    case inhaler
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tablet: return "Tablet"
        case .capsule: return "Capsule"
        case .liquid: return "Liquid"
        case .injection: return "Injection"
        case .patch: return "Patch"
        case .inhaler: return "Inhaler"
        case .other: return "Other"
        }
    }
}

enum MedicationReminderFrequency: String, CaseIterable, Codable, Identifiable {
    case daily
    case weekdays
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .weekly: return "Weekly"
        }
    }
}

struct MedicationDosageReminder: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String = "Dose"
    var frequency: MedicationReminderFrequency = .daily
    var time: Date = .now
}

@Model
final class CareTask {
    var id: UUID
    var title: String
    var taskNotes: String
    var dueDate: Date
    var categoryRawValue: String
    var assignedMemberName: String?
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var completedByName: String?
    var reminderEnabled: Bool
    var reminderMinutesBefore: Int
    var calendarEventIdentifier: String?

    // Recurrence and sharing fields are optional to make development-store migration safer.
    var seriesIdentifier: UUID?
    var repeatFrequencyRawValue: String?
    var repeatEndDate: Date?
    var visibilityRawValue: String?
    var notificationRecipientNamesData: Data?
    var scheduledNotificationIdentifiersData: Data?

    // Medication-specific fields.
    var medicationName: String?
    var medicationTypeRawValue: String?
    var dosageAmount: String?
    var medicationStartDate: Date?
    var medicationEndDate: Date?
    var dosageRemindersData: Data?

    // Appointment-specific fields.
    var doctorName: String?
    var clinicName: String?

    // Lightweight history used by KinCare AI summaries.
    // Optional fields keep development-store migration safer.
    var lastModifiedAt: Date?
    var previousAssignedMemberName: String?
    var reassignmentCount: Int?

    init(
        id: UUID = UUID(),
        title: String,
        taskNotes: String = "",
        dueDate: Date,
        category: CareTaskCategory = .other,
        assignedMemberName: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil,
        completedByName: String? = nil,
        reminderEnabled: Bool = true,
        reminderMinutesBefore: Int = 30,
        calendarEventIdentifier: String? = nil,
        seriesIdentifier: UUID? = nil,
        repeatFrequency: TaskRepeatFrequency = .never,
        repeatEndDate: Date? = nil,
        visibility: CareTaskVisibility = .careCircle,
        notificationRecipientNames: [String] = [],
        medicationName: String? = nil,
        medicationType: MedicationType? = nil,
        dosageAmount: String? = nil,
        medicationStartDate: Date? = nil,
        medicationEndDate: Date? = nil,
        dosageReminders: [MedicationDosageReminder] = [],
        doctorName: String? = nil,
        clinicName: String? = nil,
        lastModifiedAt: Date? = nil,
        previousAssignedMemberName: String? = nil,
        reassignmentCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.taskNotes = taskNotes
        self.dueDate = dueDate
        self.categoryRawValue = category.rawValue
        self.assignedMemberName = assignedMemberName
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.completedByName = completedByName
        self.reminderEnabled = reminderEnabled
        self.reminderMinutesBefore = reminderMinutesBefore
        self.calendarEventIdentifier = calendarEventIdentifier
        self.seriesIdentifier = seriesIdentifier ?? id
        self.repeatFrequencyRawValue = repeatFrequency.rawValue
        self.repeatEndDate = repeatEndDate
        self.visibilityRawValue = visibility.rawValue
        self.medicationName = medicationName
        self.medicationTypeRawValue = medicationType?.rawValue
        self.dosageAmount = dosageAmount
        self.medicationStartDate = medicationStartDate
        self.medicationEndDate = medicationEndDate
        self.doctorName = doctorName
        self.clinicName = clinicName
        self.lastModifiedAt = lastModifiedAt ?? createdAt
        self.previousAssignedMemberName = previousAssignedMemberName
        self.reassignmentCount = reassignmentCount
        self.notificationRecipientNames = notificationRecipientNames
        self.dosageReminders = dosageReminders
        self.scheduledNotificationIdentifiers = []
    }

    var category: CareTaskCategory {
        get { CareTaskCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var repeatFrequency: TaskRepeatFrequency {
        get {
            guard let rawValue = repeatFrequencyRawValue else { return .never }
            return TaskRepeatFrequency(rawValue: rawValue) ?? .never
        }
        set { repeatFrequencyRawValue = newValue.rawValue }
    }

    var visibility: CareTaskVisibility {
        get {
            guard let rawValue = visibilityRawValue else { return .careCircle }
            return CareTaskVisibility(rawValue: rawValue) ?? .careCircle
        }
        set { visibilityRawValue = newValue.rawValue }
    }

    var medicationType: MedicationType? {
        get {
            guard let rawValue = medicationTypeRawValue else { return nil }
            return MedicationType(rawValue: rawValue)
        }
        set { medicationTypeRawValue = newValue?.rawValue }
    }

    var dosageReminders: [MedicationDosageReminder] {
        get { decode([MedicationDosageReminder].self, from: dosageRemindersData) ?? [] }
        set { dosageRemindersData = encode(newValue) }
    }

    var notificationRecipientNames: [String] {
        get { decode([String].self, from: notificationRecipientNamesData) ?? [] }
        set { notificationRecipientNamesData = encode(newValue) }
    }

    var scheduledNotificationIdentifiers: [String] {
        get { decode([String].self, from: scheduledNotificationIdentifiersData) ?? [] }
        set { scheduledNotificationIdentifiersData = encode(newValue) }
    }

    var notificationIdentifier: String {
        "care-task-\(id.uuidString)"
    }

    var effectiveLastModifiedAt: Date {
        lastModifiedAt ?? createdAt
    }

    var totalReassignments: Int {
        reassignmentCount ?? 0
    }

    var displayDate: Date {
        if category == .medication,
           let nextDose = nextMedicationReminderDate(after: .now) {
            return nextDose
        }
        return dueDate
    }

    var detailSummary: String? {
        switch category {
        case .medication:
            let values = [medicationName, dosageAmount]
                .compactMap { value -> String? in
                    guard let value, !value.isEmpty else { return nil }
                    return value
                }
            return values.isEmpty ? nil : values.joined(separator: " • ")
        case .appointment:
            let values = [doctorName, clinicName]
                .compactMap { value -> String? in
                    guard let value, !value.isEmpty else { return nil }
                    return value
                }
            return values.isEmpty ? nil : values.joined(separator: " • ")
        default:
            return nil
        }
    }

    func nextOccurrenceDate() -> Date? {
        guard let next = repeatFrequency.nextDate(after: dueDate) else { return nil }
        if let repeatEndDate, next > repeatEndDate { return nil }
        return next
    }

    func nextMedicationReminderDate(
        after referenceDate: Date,
        calendar: Calendar = .current
    ) -> Date? {
        let reminders = dosageReminders
        guard !reminders.isEmpty else { return medicationStartDate ?? dueDate }

        let startDate = medicationStartDate ?? dueDate
        let endDate = medicationEndDate
        var candidates: [Date] = []

        for reminder in reminders {
            let startOfReference = calendar.startOfDay(for: max(referenceDate, startDate))
            for dayOffset in 0...14 {
                guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfReference) else {
                    continue
                }

                let weekday = calendar.component(.weekday, from: day)
                let startWeekday = calendar.component(.weekday, from: startDate)
                let shouldInclude: Bool

                switch reminder.frequency {
                case .daily:
                    shouldInclude = true
                case .weekdays:
                    shouldInclude = (2...6).contains(weekday)
                case .weekly:
                    shouldInclude = weekday == startWeekday
                }

                guard shouldInclude else { continue }

                let time = calendar.dateComponents([.hour, .minute], from: reminder.time)
                guard let occurrence = calendar.date(
                    bySettingHour: time.hour ?? 9,
                    minute: time.minute ?? 0,
                    second: 0,
                    of: day
                ) else {
                    continue
                }

                if occurrence >= referenceDate,
                   occurrence >= startDate,
                   endDate == nil || occurrence <= endDate! {
                    candidates.append(occurrence)
                    break
                }
            }
        }

        return candidates.min()
    }

    func copyForNextOccurrence(on date: Date) -> CareTask {
        CareTask(
            title: title,
            taskNotes: taskNotes,
            dueDate: date,
            category: category,
            assignedMemberName: assignedMemberName,
            reminderEnabled: reminderEnabled,
            reminderMinutesBefore: reminderMinutesBefore,
            seriesIdentifier: seriesIdentifier ?? id,
            repeatFrequency: repeatFrequency,
            repeatEndDate: repeatEndDate,
            visibility: visibility,
            notificationRecipientNames: notificationRecipientNames,
            medicationName: medicationName,
            medicationType: medicationType,
            dosageAmount: dosageAmount,
            medicationStartDate: medicationStartDate,
            medicationEndDate: medicationEndDate,
            dosageReminders: dosageReminders,
            doctorName: doctorName,
            clinicName: clinicName
        )
    }

    var calendarNotes: String {
        var lines: [String] = []
        if !taskNotes.isEmpty { lines.append(taskNotes) }

        if category == .medication {
            if let medicationName, !medicationName.isEmpty {
                lines.append("Medication: \(medicationName)")
            }
            if let medicationType {
                lines.append("Type: \(medicationType.title)")
            }
            if let dosageAmount, !dosageAmount.isEmpty {
                lines.append("Amount per dosage: \(dosageAmount)")
            }
        }

        if category == .appointment {
            if let doctorName, !doctorName.isEmpty {
                lines.append("Doctor: \(doctorName)")
            }
            if let clinicName, !clinicName.isEmpty {
                lines.append("Hospital/Clinic: \(clinicName)")
            }
        }

        if !notificationRecipientNames.isEmpty {
            lines.append("KinCare reminder recipients: \(notificationRecipientNames.joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
