import Foundation
import SwiftData

enum CareMemberRole: String, CaseIterable, Codable, Identifiable {
    case caregiver
    case supporter
    case viewer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caregiver: "Caregiver"
        case .supporter: "Supporter"
        case .viewer: "Viewer"
        }
    }

    var description: String {
        switch self {
        case .caregiver:
            "Can create, assign, and complete care tasks."
        case .supporter:
            "Can help with tasks shared with them."
        case .viewer:
            "Can view selected care information without making changes."
        }
    }
}

@Model
final class CareMember {
    var id: UUID
    var name: String
    var roleRawValue: String
    var relationshipToRecipient: String = ""
    var isAvailable: Bool
    var availabilityNote: String
    var availabilitySlotRawValues: String = ""
    var preferredCategoryRawValues: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        role: CareMemberRole,
        relationshipToRecipient: String = "",
        isAvailable: Bool = true,
        availabilityNote: String = "",
        availabilitySlots: [WeeklyAvailabilitySlot] = [],
        preferredCategories: [CareTaskCategory] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.roleRawValue = role.rawValue
        self.relationshipToRecipient = relationshipToRecipient
        self.isAvailable = isAvailable
        self.availabilityNote = availabilityNote.isEmpty
            ? availabilitySlots.availabilitySummary
            : availabilityNote
        self.availabilitySlotRawValues = availabilitySlots
            .map(\.storageValue)
            .joined(separator: ",")
        self.preferredCategoryRawValues = preferredCategories
            .map(\.rawValue)
            .joined(separator: ",")
        self.createdAt = createdAt
    }

    var role: CareMemberRole {
        get { CareMemberRole(rawValue: roleRawValue) ?? .supporter }
        set { roleRawValue = newValue.rawValue }
    }

    var availabilitySlots: [WeeklyAvailabilitySlot] {
        get {
            availabilitySlotRawValues
                .split(separator: ",")
                .compactMap {
                    WeeklyAvailabilitySlot(storageValue: String($0))
                }
        }
        set {
            availabilitySlotRawValues = newValue
                .map(\.storageValue)
                .joined(separator: ",")
            availabilityNote = newValue.availabilitySummary
            isAvailable = !newValue.isEmpty
        }
    }

    var preferredCategories: [CareTaskCategory] {
        get {
            preferredCategoryRawValues
                .split(separator: ",")
                .compactMap { CareTaskCategory(rawValue: String($0)) }
        }
        set {
            preferredCategoryRawValues = newValue
                .map(\.rawValue)
                .joined(separator: ",")
        }
    }
}
