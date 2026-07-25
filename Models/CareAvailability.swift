import Foundation

enum CareRelationship: String, CaseIterable, Codable, Identifiable {
    case friend
    case mother
    case father
    case spouseOrPartner
    case child
    case sibling
    case aunt
    case uncle
    case cousin
    case neighbor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .friend: "Friend"
        case .mother: "Mother"
        case .father: "Father"
        case .spouseOrPartner: "Spouse or partner"
        case .child: "Child"
        case .sibling: "Sibling"
        case .aunt: "Aunt"
        case .uncle: "Uncle"
        case .cousin: "Cousin"
        case .neighbor: "Neighbor"
        }
    }
}

enum CareWeekday: String, CaseIterable, Codable, Identifiable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .monday: "M"
        case .tuesday: "T"
        case .wednesday: "W"
        case .thursday: "Th"
        case .friday: "F"
        case .saturday: "Sa"
        case .sunday: "Su"
        }
    }

    var title: String {
        rawValue.capitalized
    }
}

enum CareTimeBlock: String, CaseIterable, Codable, Identifiable {
    case morning
    case afternoon
    case evening
    case night

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var hours: String {
        switch self {
        case .morning: "6 AM–12 PM"
        case .afternoon: "12–5 PM"
        case .evening: "5–9 PM"
        case .night: "9 PM–12 AM"
        }
    }
}

struct WeeklyAvailabilitySlot: Hashable, Codable, Identifiable {
    let weekday: CareWeekday
    let timeBlock: CareTimeBlock

    var id: String {
        storageValue
    }

    var storageValue: String {
        "\(weekday.rawValue)|\(timeBlock.rawValue)"
    }

    var displayText: String {
        "\(weekday.title) \(timeBlock.title.lowercased())"
    }

    init(weekday: CareWeekday, timeBlock: CareTimeBlock) {
        self.weekday = weekday
        self.timeBlock = timeBlock
    }

    init?(storageValue: String) {
        let parts = storageValue.split(separator: "|", maxSplits: 1)
        guard parts.count == 2,
              let weekday = CareWeekday(rawValue: String(parts[0])),
              let timeBlock = CareTimeBlock(rawValue: String(parts[1])) else {
            return nil
        }

        self.weekday = weekday
        self.timeBlock = timeBlock
    }
}

extension Collection where Element == WeeklyAvailabilitySlot {
    var availabilitySummary: String {
        guard !isEmpty else { return "No availability selected" }

        let grouped = Dictionary(grouping: self, by: \.timeBlock)

        return CareTimeBlock.allCases.compactMap { block in
            guard let slots = grouped[block], !slots.isEmpty else { return nil }
            let daySet = Set(slots.map(\.weekday))
            let days = CareWeekday.allCases
                .filter(daySet.contains)
                .map(\.shortTitle)
                .joined(separator: ", ")
            return "\(days) · \(block.title)"
        }
        .joined(separator: "; ")
    }
}
