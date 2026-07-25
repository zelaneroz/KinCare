import Foundation

enum AITaskExtractionError: LocalizedError {
    case emptyRequest

    var errorDescription: String? {
        switch self {
        case .emptyRequest:
            return "Describe the care task before asking KinCare AI to organize it."
        }
    }
}

@MainActor
protocol AITaskExtracting {
    func extract(
        from text: String,
        members: [CareMember],
        careRecipientName: String,
        now: Date
    ) async throws -> AITaskDraft
}

struct LocalAITaskExtractionService: AITaskExtracting {
    func extract(
        from text: String,
        members: [CareMember],
        careRecipientName: String,
        now: Date = .now
    ) async throws -> AITaskDraft {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw AITaskExtractionError.emptyRequest }

        let category = inferCategory(from: cleaned)
        let assignedMemberName = members.first(where: {
            cleaned.range(of: $0.name, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        })?.name
        let dueDate = detectedDate(in: cleaned, now: now)
        let doctorName = firstCapture(
            pattern: #"(?i)\b(?:dr\.?|doctor)\s+([\p{L}][\p{L}'-]*(?:\s+[\p{L}][\p{L}'-]*)?)(?=\s+(?:at|on|today|tomorrow|tonight|next|this)\b|[,.]|$)"#,
            text: cleaned
        )
        let clinicName = firstCapture(
            pattern: #"(?i)\b(?:at|in)\s+([^,.]+?(?:clinic|hospital|medical center|health center))\b"#,
            text: cleaned
        )

        return AITaskDraft(
            originalText: cleaned,
            title: inferredTitle(
                from: cleaned,
                category: category,
                assignedMemberName: assignedMemberName,
                doctorName: doctorName
            ),
            category: category,
            assignedMemberName: assignedMemberName,
            dueDate: dueDate,
            doctorName: doctorName,
            clinicName: clinicName,
            careRecipientName: careRecipientName,
            suggestedReminderMinutesBefore: suggestedReminder(for: category)
        )
    }

    private func inferCategory(from text: String) -> CareTaskCategory {
        let value = text.lowercased()

        if containsAny(value, ["appointment", "doctor", "dr.", "clinic", "hospital", "checkup", "check-up"]) {
            return .appointment
        }
        if containsAny(value, ["medication", "medicine", "pill", "dose", "dosage", "prescription"]) {
            return .medication
        }
        if containsAny(value, ["breakfast", "lunch", "dinner", "meal", "cook", "food"]) {
            return .meal
        }
        if containsAny(value, ["drive", "ride", "transport", "pick up", "drop off"]) {
            return .transportation
        }
        if containsAny(value, ["laundry", "clean", "groceries", "household", "chores"]) {
            return .household
        }
        if containsAny(value, ["visit", "call", "company", "companionship", "spend time"]) {
            return .companionship
        }
        if containsAny(value, ["bath", "shower", "dress", "personal care", "diaper"]) {
            return .personalCare
        }

        return .other
    }

    private func inferredTitle(
        from text: String,
        category: CareTaskCategory,
        assignedMemberName: String?,
        doctorName: String?
    ) -> String {
        if category == .appointment, let doctorName, !doctorName.isEmpty {
            return "Appointment with Dr. \(doctorName)"
        }

        var title = text
        let prefixes = [
            #"(?i)^\s*please\s+"#,
            #"(?i)^\s*can you\s+"#,
            #"(?i)^\s*remind me to\s+"#,
            #"(?i)^\s*remind\s+[^,]+?\s+to\s+"#
        ]

        for pattern in prefixes {
            title = replacing(pattern: pattern, in: title, with: "")
        }

        if let assignedMemberName {
            title = replacing(
                pattern: "(?i)^\\s*" + NSRegularExpression.escapedPattern(for: assignedMemberName) + #"\s+to\s+"#,
                in: title,
                with: ""
            )
        }

        title = replacing(
            pattern: #"(?i)\s+(?:today|tomorrow|tonight|next\s+(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday))(?:\s+at\s+[^,.]+)?\s*$"#,
            in: title,
            with: ""
        )
        title = replacing(
            pattern: #"(?i)\s+at\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)\s*$"#,
            in: title,
            with: ""
        )

        title = title.trimmingCharacters(in: CharacterSet(charactersIn: " .,!"))

        if title.isEmpty {
            return category.title
        }

        return title.prefix(1).uppercased() + title.dropFirst()
    }

    private func detectedDate(in text: String, now: Date) -> Date? {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.date.rawValue
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return detector.firstMatch(
            in: text,
            options: [],
            range: range
        )?.date
    }

    private func suggestedReminder(for category: CareTaskCategory) -> Int {
        switch category {
        case .appointment, .transportation:
            return 60
        case .medication:
            return 15
        default:
            return 30
        }
    }

    private func containsAny(_ text: String, _ values: [String]) -> Bool {
        values.contains { text.contains($0) }
    }

    private func firstCapture(pattern: String, text: String) -> String? {
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: []
        ) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = expression.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[captureRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replacing(
        pattern: String,
        in text: String,
        with replacement: String
    ) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return expression.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: replacement
        )
    }
}
