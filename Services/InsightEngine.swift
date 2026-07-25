import Foundation

enum InsightPriority {
    case gentle
    case attention
}

enum CareInsightKind: String {
    case careTask
    case workloadImbalance
    case lastMinuteAssignments
    case repeatedMisses
    case consecutiveCareDays
    case caregiverCapacity
}

struct CareInsightItem: Identifiable {
    let id = UUID()
    let kind: CareInsightKind
    let priority: InsightPriority
    let title: String
    let message: String
    let actionTitle: String?
    let suggestedMemberName: String?
    let suggestedTaskTitle: String?
}

struct CareInsightDigest: Identifiable {
    let id = UUID()
    let items: [CareInsightItem]
    let overdueTaskCount: Int

    var priority: InsightPriority {
        items.contains(where: { $0.priority == .attention }) ? .attention : .gentle
    }

    var title: String {
        let patternCount = items.filter { $0.kind != .careTask }.count
        let totalCount = overdueTaskCount + patternCount

        if overdueTaskCount > 0 && patternCount == 0 {
            return "\(overdueTaskCount) care task\(overdueTaskCount == 1 ? "" : "s") need attention"
        }

        return "\(max(totalCount, items.count)) care item\(max(totalCount, items.count) == 1 ? "" : "s") need attention"
    }
}

enum InsightEngine {
    static func makeInsight(
        tasks: [CareTask],
        members: [CareMember],
        checkIns: [CapacityCheckIn],
        now: Date = .now
    ) -> CareInsightDigest? {
        let calendar = Calendar.current
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        var items: [CareInsightItem] = []

        let overdue = tasks
            .filter { !$0.isCompleted && $0.dueDate < now }
            .sorted(by: { $0.dueDate < $1.dueDate })

        if let firstOverdue = overdue.first {
            let helper = bestAvailableHelper(
                for: firstOverdue.category,
                members: members
            )

            let message: String
            if let helper {
                let availability = helper.availabilityNote.isEmpty
                    ? "is in your CareCrew"
                    : "is available \(helper.availabilityNote.lowercased())"
                message = "“\(firstOverdue.title)” is overdue. \(helper.name) \(availability) and may be able to cover it."
            } else {
                message = "“\(firstOverdue.title)” is overdue. Review whether it should be completed, reassigned, or rescheduled."
            }

            items.append(
                CareInsightItem(
                    kind: .careTask,
                    priority: .attention,
                    title: overdue.count == 1
                        ? "One task is overdue"
                        : "\(overdue.count) tasks are overdue",
                    message: message,
                    actionTitle: "Ask for coverage",
                    suggestedMemberName: helper?.name,
                    suggestedTaskTitle: firstOverdue.title
                )
            )
        }

        if let latestCheckIn = checkIns.sorted(by: { $0.date > $1.date }).first,
           latestCheckIn.date >= weekStart,
           latestCheckIn.stress >= 4 || latestCheckIn.energy <= 2 {
            let nextTask = nextDelegatableTask(from: tasks, now: now)
            let helper = bestAvailableHelper(
                for: nextTask?.category ?? .other,
                members: members
            )

            items.append(
                CareInsightItem(
                    kind: .caregiverCapacity,
                    priority: .attention,
                    title: "Your capacity looks stretched",
                    message: helper.map {
                        "Your latest check-in shows high strain. \($0.name) is in your CareCrew and may be able to take the next task."
                    } ?? "Your latest check-in shows high strain. Consider handing off or postponing one nonessential task.",
                    actionTitle: "Ask for coverage",
                    suggestedMemberName: helper?.name,
                    suggestedTaskTitle: nextTask?.title
                )
            )
        }

        let recentCompletions = tasks.filter {
            guard $0.isCompleted, let completedAt = $0.completedAt else { return false }
            return completedAt >= weekStart && completedAt <= now
        }

        let completedByYou = recentCompletions.filter {
            ($0.completedByName ?? $0.assignedMemberName ?? "You") == "You"
        }

        if recentCompletions.count >= 5 {
            let yourShare = Double(completedByYou.count) / Double(recentCompletions.count)

            if yourShare >= 0.75 {
                let nextTask = nextDelegatableTask(from: tasks, now: now)
                let helper = bestAvailableHelper(
                    for: nextTask?.category ?? .other,
                    members: members
                )

                items.append(
                    CareInsightItem(
                        kind: .workloadImbalance,
                        priority: .attention,
                        title: "You carried most of the care this week",
                        message: helper.map {
                            "You completed \(completedByYou.count) of \(recentCompletions.count) recent tasks. \($0.name) may be a good fit for the next handoff."
                        } ?? "You completed \(completedByYou.count) of \(recentCompletions.count) recent tasks. Consider asking your CareCrew to take the next one.",
                        actionTitle: "Ask for coverage",
                        suggestedMemberName: helper?.name,
                        suggestedTaskTitle: nextTask?.title
                    )
                )
            }
        }

        let lastMinuteAssignments = tasks.filter { task in
            guard task.createdAt >= weekStart,
                  task.assignedMemberName != nil,
                  task.dueDate >= task.createdAt else {
                return false
            }

            return task.dueDate.timeIntervalSince(task.createdAt) <= 12 * 60 * 60
        }

        if lastMinuteAssignments.count >= 2 {
            items.append(
                CareInsightItem(
                    kind: .lastMinuteAssignments,
                    priority: .gentle,
                    title: "Several tasks were assigned at the last minute",
                    message: "\(lastMinuteAssignments.count) tasks were created or assigned within 12 hours of their due time. Earlier requests may make it easier for your CareCrew to say yes.",
                    actionTitle: nil,
                    suggestedMemberName: nil,
                    suggestedTaskTitle: nil
                )
            )
        }

        if overdue.count >= 2 {
            let repeatedTitles = Dictionary(grouping: overdue) {
                $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
            .filter { $0.value.count >= 2 }

            let message: String
            if let repeated = repeatedTitles.first?.value.first {
                message = "“\(repeated.title)” has been missed more than once. Consider changing its reminder, assignee, or schedule."
            } else {
                message = "\(overdue.count) tasks are currently overdue. A recurring reminder or clearer ownership may help."
            }

            items.append(
                CareInsightItem(
                    kind: .repeatedMisses,
                    priority: .attention,
                    title: "Care tasks are being missed repeatedly",
                    message: message,
                    actionTitle: nil,
                    suggestedMemberName: nil,
                    suggestedTaskTitle: nil
                )
            )
        }

        let consecutiveDays = consecutiveCareDays(
            from: recentCompletions,
            caregiverName: "You",
            calendar: calendar,
            now: now
        )

        if consecutiveDays >= 3 {
            let nextTask = nextDelegatableTask(from: tasks, now: now)
            let helper = bestAvailableHelper(
                for: nextTask?.category ?? .other,
                members: members
            )

            items.append(
                CareInsightItem(
                    kind: .consecutiveCareDays,
                    priority: .gentle,
                    title: "You have provided care for \(consecutiveDays) days in a row",
                    message: helper.map {
                        "A small handoff to \($0.name) could create space for a break."
                    } ?? "Consider asking the CareCrew to cover one upcoming responsibility.",
                    actionTitle: "Ask for coverage",
                    suggestedMemberName: helper?.name,
                    suggestedTaskTitle: nextTask?.title
                )
            )
        }

        guard !items.isEmpty else { return nil }

        return CareInsightDigest(
            items: Array(items.prefix(6)),
            overdueTaskCount: overdue.count
        )
    }

    private static func consecutiveCareDays(
        from tasks: [CareTask],
        caregiverName: String,
        calendar: Calendar,
        now: Date
    ) -> Int {
        let completionDays = Set(
            tasks.compactMap { task -> Date? in
                guard let completedAt = task.completedAt,
                      (task.completedByName ?? task.assignedMemberName ?? "You") == caregiverName else {
                    return nil
                }
                return calendar.startOfDay(for: completedAt)
            }
        )

        guard !completionDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: now)
        if !completionDays.contains(cursor),
           let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
           completionDays.contains(yesterday) {
            cursor = yesterday
        }

        var count = 0
        while completionDays.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }

        return count
    }

    private static func nextDelegatableTask(
        from tasks: [CareTask],
        now: Date
    ) -> CareTask? {
        tasks
            .filter {
                !$0.isCompleted &&
                $0.dueDate >= now &&
                ($0.assignedMemberName == nil || $0.assignedMemberName == "You")
            }
            .sorted(by: { $0.dueDate < $1.dueDate })
            .first
    }

    private static func bestAvailableHelper(
        for category: CareTaskCategory,
        members: [CareMember]
    ) -> CareMember? {
        let helpers = members.filter {
            $0.isAvailable &&
            $0.name != "You" &&
            $0.role != .viewer
        }

        return helpers.first(where: {
            $0.preferredCategories.contains(category)
        }) ?? helpers.first
    }
}
