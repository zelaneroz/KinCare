import Foundation

struct AITaskDraft: Identifiable {
    let id = UUID()
    var originalText: String
    var title: String
    var category: CareTaskCategory
    var assignedMemberName: String?
    var dueDate: Date?
    var doctorName: String?
    var clinicName: String?
    var careRecipientName: String
    var suggestedReminderMinutesBefore: Int

    var reminderDescription: String {
        switch suggestedReminderMinutesBefore {
        case 0:
            return "At the due time"
        case 15:
            return "15 minutes before"
        case 30:
            return "30 minutes before"
        case 60:
            return "1 hour before"
        case 1_440:
            return "1 day before"
        default:
            return "\(suggestedReminderMinutesBefore) minutes before"
        }
    }
}
