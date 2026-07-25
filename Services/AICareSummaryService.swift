import Foundation

// The protocol keeps summary generation replaceable. The MVP implementation
// works locally; a Foundation Models or hosted provider can conform later.
@MainActor
protocol AICareSummaryGenerating {
    func generate(
        kind: AICareSummaryKind,
        tasks: [CareTask],
        recipientName: String,
        now: Date
    ) -> AICareSummary
}

enum AICareSummaryKind: String, CaseIterable, Identifiable {
    case today
    case weekly
    case upcoming
    case attention

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .weekly: return "Weekly update"
        case .upcoming: return "Upcoming care"
        case .attention: return "Needs attention"
        }
    }

    var promptTitle: String {
        switch self {
        case .today: return "What happened today?"
        case .weekly: return "Weekly CareCrew update"
        case .upcoming: return "Upcoming appointments and medications"
        case .attention: return "Uncompleted or reassigned tasks"
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max"
        case .weekly: return "calendar.badge.clock"
        case .upcoming: return "calendar"
        case .attention: return "exclamationmark.circle"
        }
    }
}

struct AICareSummarySection: Identifiable, Hashable {
    let id = UUID()
    let heading: String
    let items: [String]
}

struct AICareSummary {
    let kind: AICareSummaryKind
    let recipientName: String
    let generatedAt: Date
    let opening: String
    let sections: [AICareSummarySection]

    var shareText: String {
        var lines = [kind.promptTitle, opening]

        for section in sections where !section.items.isEmpty {
            lines.append("")
            lines.append(section.heading)
            lines.append(contentsOf: section.items.map { "• \($0)" })
        }

        lines.append("")
        lines.append("Generated with KinCare AI. Please review before sharing.")
        return lines.joined(separator: "\n")
    }
}

@MainActor
struct LocalAICareSummaryService: AICareSummaryGenerating {
    func generate(
        kind: AICareSummaryKind,
        tasks: [CareTask],
        recipientName: String,
        now: Date = .now
    ) -> AICareSummary {
        switch kind {
        case .today:
            return todaySummary(tasks: tasks, recipientName: recipientName, now: now)
        case .weekly:
            return weeklySummary(tasks: tasks, recipientName: recipientName, now: now)
        case .upcoming:
            return upcomingSummary(tasks: tasks, recipientName: recipientName, now: now)
        case .attention:
            return attentionSummary(tasks: tasks, recipientName: recipientName, now: now)
        }
    }

    private func todaySummary(
        tasks: [CareTask],
        recipientName: String,
        now: Date
    ) -> AICareSummary {
        let calendar = Calendar.current
        let completed = tasks.filter {
            guard $0.isCompleted, let completedAt = $0.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: now)
        }
        let remaining = tasks.filter {
            !$0.isCompleted && calendar.isDate($0.dueDate, inSameDayAs: now)
        }
        let overdue = tasks.filter { !$0.isCompleted && $0.dueDate < now }

        let sections = [
            AICareSummarySection(
                heading: "Completed",
                items: completed.isEmpty
                    ? ["No tasks have been marked complete today."]
                    : completed.prefix(5).map(completedLine)
            ),
            AICareSummarySection(
                heading: "Still ahead",
                items: remaining.isEmpty
                    ? ["No additional care tasks are scheduled for today."]
                    : remaining.sorted(by: { $0.dueDate < $1.dueDate }).prefix(5).map(taskLine)
            ),
            AICareSummarySection(
                heading: "Needs follow-up",
                items: overdue.isEmpty
                    ? ["There are no overdue tasks."]
                    : overdue.sorted(by: { $0.dueDate < $1.dueDate }).prefix(4).map(overdueLine)
            )
        ]

        return AICareSummary(
            kind: .today,
            recipientName: recipientName,
            generatedAt: now,
            opening: completed.isEmpty && remaining.isEmpty
                ? "There was little recorded care activity for \(recipientName) today."
                : "Here is the care activity recorded for \(recipientName) today.",
            sections: sections
        )
    }

    private func weeklySummary(
        tasks: [CareTask],
        recipientName: String,
        now: Date
    ) -> AICareSummary {
        let calendar = Calendar.current
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now

        let completed = tasks.filter {
            guard $0.isCompleted, let completedAt = $0.completedAt else { return false }
            return completedAt >= weekStart && completedAt <= now
        }

        let grouped = Dictionary(grouping: completed) {
            $0.completedByName ?? $0.assignedMemberName ?? "Unassigned"
        }
        let contributionLines = grouped
            .map { "\($0.key) completed \($0.value.count) task\($0.value.count == 1 ? "" : "s")." }
            .sorted()

        let medicationUpdates = tasks.filter {
            $0.category == .medication &&
            $0.effectiveLastModifiedAt >= weekStart &&
            $0.effectiveLastModifiedAt <= now
        }

        let upcomingAppointments = tasks.filter {
            !$0.isCompleted &&
            $0.category == .appointment &&
            $0.dueDate >= now &&
            $0.dueDate <= nextWeek
        }

        let unresolved = tasks.filter {
            !$0.isCompleted && ($0.dueDate < now || $0.totalReassignments > 0)
        }

        return AICareSummary(
            kind: .weekly,
            recipientName: recipientName,
            generatedAt: now,
            opening: "This week, the CareCrew completed \(completed.count) task\(completed.count == 1 ? "" : "s") for \(recipientName).",
            sections: [
                AICareSummarySection(
                    heading: "CareCrew activity",
                    items: contributionLines.isEmpty
                        ? ["No completed tasks were recorded this week."]
                        : Array(contributionLines.prefix(6))
                ),
                AICareSummarySection(
                    heading: "Medication changes",
                    items: medicationUpdates.isEmpty
                        ? ["No medication tasks were added or edited this week."]
                        : medicationUpdates.prefix(5).map(medicationUpdateLine)
                ),
                AICareSummarySection(
                    heading: "Next appointments",
                    items: upcomingAppointments.isEmpty
                        ? ["No appointments are scheduled in the next seven days."]
                        : upcomingAppointments.sorted(by: { $0.dueDate < $1.dueDate }).prefix(5).map(appointmentLine)
                ),
                AICareSummarySection(
                    heading: "Follow-up",
                    items: unresolved.isEmpty
                        ? ["No overdue or reassigned tasks need follow-up."]
                        : unresolved.prefix(5).map(attentionLine)
                )
            ]
        )
    }

    private func upcomingSummary(
        tasks: [CareTask],
        recipientName: String,
        now: Date
    ) -> AICareSummary {
        let end = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let open = tasks.filter {
            !$0.isCompleted && $0.dueDate >= now && $0.dueDate <= end
        }

        let appointments = open
            .filter { $0.category == .appointment }
            .sorted(by: { $0.dueDate < $1.dueDate })
        let medications = open
            .filter { $0.category == .medication }
            .sorted(by: { $0.displayDate < $1.displayDate })
        let other = open
            .filter { $0.category != .appointment && $0.category != .medication }
            .sorted(by: { $0.dueDate < $1.dueDate })

        return AICareSummary(
            kind: .upcoming,
            recipientName: recipientName,
            generatedAt: now,
            opening: "Here is the care currently scheduled for \(recipientName) over the next seven days.",
            sections: [
                AICareSummarySection(
                    heading: "Appointments",
                    items: appointments.isEmpty
                        ? ["No appointments are scheduled."]
                        : appointments.prefix(5).map(appointmentLine)
                ),
                AICareSummarySection(
                    heading: "Medications",
                    items: medications.isEmpty
                        ? ["No medication tasks are scheduled."]
                        : medications.prefix(5).map(medicationLine)
                ),
                AICareSummarySection(
                    heading: "Other care",
                    items: other.isEmpty
                        ? ["No other care tasks are scheduled."]
                        : other.prefix(5).map(taskLine)
                )
            ]
        )
    }

    private func attentionSummary(
        tasks: [CareTask],
        recipientName: String,
        now: Date
    ) -> AICareSummary {
        let threeDays = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        let overdue = tasks
            .filter { !$0.isCompleted && $0.dueDate < now }
            .sorted(by: { $0.dueDate < $1.dueDate })
        let unassigned = tasks
            .filter {
                !$0.isCompleted &&
                $0.dueDate >= now &&
                $0.dueDate <= threeDays &&
                ($0.assignedMemberName?.isEmpty ?? true)
            }
            .sorted(by: { $0.dueDate < $1.dueDate })
        let reassigned = tasks
            .filter {
                $0.totalReassignments > 0 &&
                $0.effectiveLastModifiedAt >= weekStart
            }
            .sorted(by: { $0.effectiveLastModifiedAt > $1.effectiveLastModifiedAt })

        let count = overdue.count + unassigned.count + reassigned.count
        return AICareSummary(
            kind: .attention,
            recipientName: recipientName,
            generatedAt: now,
            opening: count == 0
                ? "Nothing currently needs extra coordination for \(recipientName)."
                : "KinCare found \(count) item\(count == 1 ? "" : "s") that may need CareCrew follow-up.",
            sections: [
                AICareSummarySection(
                    heading: "Uncompleted",
                    items: overdue.isEmpty
                        ? ["No overdue tasks."]
                        : overdue.prefix(6).map(overdueLine)
                ),
                AICareSummarySection(
                    heading: "Unassigned soon",
                    items: unassigned.isEmpty
                        ? ["Every task due in the next three days has an assignee."]
                        : unassigned.prefix(6).map(taskLine)
                ),
                AICareSummarySection(
                    heading: "Reassigned",
                    items: reassigned.isEmpty
                        ? ["No tasks were reassigned this week."]
                        : reassigned.prefix(6).map(reassignmentLine)
                )
            ]
        )
    }

    private func taskLine(_ task: CareTask) -> String {
        "\(task.title) — \(formatted(task.dueDate))\(assigneeSuffix(task))."
    }

    private func completedLine(_ task: CareTask) -> String {
        let person = task.completedByName ?? task.assignedMemberName ?? "CareCrew"
        return "\(task.title) was completed by \(person)."
    }

    private func overdueLine(_ task: CareTask) -> String {
        "\(task.title) was due \(formatted(task.dueDate))\(assigneeSuffix(task))."
    }

    private func appointmentLine(_ task: CareTask) -> String {
        let details = [task.doctorName, task.clinicName]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " at ")
        let suffix = details.isEmpty ? "" : " — \(details)"
        return "\(task.title) on \(formatted(task.dueDate))\(suffix)\(assigneeSuffix(task))."
    }

    private func medicationLine(_ task: CareTask) -> String {
        let name = task.medicationName ?? task.title
        let amount = task.dosageAmount.map { $0.isEmpty ? "" : ", \($0)" } ?? ""
        return "\(name)\(amount) — next at \(formatted(task.displayDate))\(assigneeSuffix(task))."
    }

    private func medicationUpdateLine(_ task: CareTask) -> String {
        let name = task.medicationName ?? task.title
        let action = task.createdAt == task.effectiveLastModifiedAt ? "added" : "updated"
        return "\(name) was \(action) \(relative(task.effectiveLastModifiedAt))."
    }

    private func attentionLine(_ task: CareTask) -> String {
        if task.dueDate < .now { return overdueLine(task) }
        return reassignmentLine(task)
    }

    private func reassignmentLine(_ task: CareTask) -> String {
        let from = task.previousAssignedMemberName.map { " from \($0)" } ?? ""
        let to = task.assignedMemberName.map { " to \($0)" } ?? " to unassigned"
        return "\(task.title) was reassigned\(from)\(to)."
    }

    private func assigneeSuffix(_ task: CareTask) -> String {
        task.assignedMemberName.map { " • \($0)" } ?? " • Unassigned"
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private func relative(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: .now)
    }
}
