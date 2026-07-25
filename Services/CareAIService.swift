import Foundation

protocol CareAIService {
    func draftHelpRequest(
        caregiverName: String,
        helperName: String?,
        taskTitle: String?
    ) async throws -> String
}

struct RuleBasedCareAIService: CareAIService {
    func draftHelpRequest(
        caregiverName: String,
        helperName: String?,
        taskTitle: String?
    ) async throws -> String {
        let greeting = helperName.map { "Hi \($0)," } ?? "Hi,"
        let task = taskTitle ?? "one care task this week"

        return """
        \(greeting) I’ve been carrying a little more of the care load lately. Would you be able to help with \(task)? No pressure if your schedule does not allow it—just let me know what works. Thank you.
        """
    }
}

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
struct FoundationModelCareAIService: CareAIService {
    private let session = LanguageModelSession(
        instructions: """
        You help family caregivers ask trusted people for practical support.
        Write one warm, direct, guilt-free message. Never provide medical advice.
        Do not claim that a message was sent. Keep the result under 80 words.
        """
    )

    func draftHelpRequest(
        caregiverName: String,
        helperName: String?,
        taskTitle: String?
    ) async throws -> String {
        let response = try await session.respond(
            to: """
            Caregiver: \(caregiverName)
            Recipient of message: \(helperName ?? "a trusted helper")
            Requested help: \(taskTitle ?? "take one upcoming care task")
            Draft the message.
            """
        )
        return response.content
    }
}
#endif
