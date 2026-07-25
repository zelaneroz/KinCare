import Foundation
import SwiftData

enum HealthCondition: String, CaseIterable, Codable, Identifiable {
    case alzheimersOrDementia
    case cancer
    case diabetes
    case heartCondition
    case mobilityLimitation
    case postSurgeryRecovery
    case strokeRecovery
    case chronicPain
    case mentalHealthCondition
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alzheimersOrDementia:
            "Alzheimer’s or dementia"
        case .cancer:
            "Cancer"
        case .diabetes:
            "Diabetes"
        case .heartCondition:
            "Heart condition"
        case .mobilityLimitation:
            "Mobility limitation"
        case .postSurgeryRecovery:
            "Post-surgery recovery"
        case .strokeRecovery:
            "Stroke recovery"
        case .chronicPain:
            "Chronic pain"
        case .mentalHealthCondition:
            "Mental health condition"
        case .other:
            "Other"
        }
    }
}

@Model
final class CareRecipient {
    var id: UUID
    var firstName: String
    var relationship: String
    var careNotes: String
    var healthConditionsRawValue: String = ""
    var zipCode: String = ""
    var healthInsurance: String = ""
    var createdAt: Date

    init(
        id: UUID = UUID(),
        firstName: String,
        relationship: String,
        careNotes: String = "",
        healthConditions: [HealthCondition] = [],
        zipCode: String = "",
        healthInsurance: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.firstName = firstName
        self.relationship = relationship
        self.careNotes = careNotes
        self.healthConditionsRawValue = healthConditions
            .map(\.rawValue)
            .joined(separator: ",")
        self.zipCode = zipCode
        self.healthInsurance = healthInsurance
        self.createdAt = createdAt
    }

    var healthConditions: [HealthCondition] {
        get {
            healthConditionsRawValue
                .split(separator: ",")
                .compactMap { HealthCondition(rawValue: String($0)) }
        }
        set {
            healthConditionsRawValue = newValue
                .map(\.rawValue)
                .joined(separator: ",")
        }
    }
}
