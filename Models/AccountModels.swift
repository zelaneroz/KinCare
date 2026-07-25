import Foundation
import SwiftData

enum OnboardingSource: String, Codable {
    case createdCareCrew
    case joinedWithCode
    case joinedWithInviteLink
}

@Model
final class UserProfile {
    var id: UUID
    var phoneNumber: String
    var firstName: String
    var lastName: String
    var isPhoneVerified: Bool
    var careContextFirstResponse: String
    var careContextSecondResponse: String
    var onboardingSourceRawValue: String
    var currentCareCrewCode: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        phoneNumber: String,
        firstName: String,
        lastName: String,
        isPhoneVerified: Bool,
        careContextFirstResponse: String = "",
        careContextSecondResponse: String = "",
        onboardingSource: OnboardingSource,
        currentCareCrewCode: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.isPhoneVerified = isPhoneVerified
        self.careContextFirstResponse = careContextFirstResponse
        self.careContextSecondResponse = careContextSecondResponse
        self.onboardingSourceRawValue = onboardingSource.rawValue
        self.currentCareCrewCode = currentCareCrewCode
        self.createdAt = createdAt
    }

    var onboardingSource: OnboardingSource {
        get {
            OnboardingSource(rawValue: onboardingSourceRawValue) ?? .createdCareCrew
        }
        set {
            onboardingSourceRawValue = newValue.rawValue
        }
    }

    var fullName: String {
        "\(firstName) \(lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isOnboardingComplete: Bool {
        isPhoneVerified &&
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !currentCareCrewCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@Model
final class CareCrew {
    var id: UUID
    var name: String
    var invitationCode: String
    var recipientName: String
    var isOwner: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        invitationCode: String,
        recipientName: String,
        isOwner: Bool,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.invitationCode = invitationCode
        self.recipientName = recipientName
        self.isOwner = isOwner
        self.createdAt = createdAt
    }
}
