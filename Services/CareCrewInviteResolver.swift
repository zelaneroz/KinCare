import Foundation

struct ResolvedCareCrewInvite: Sendable {
    let code: String
    let recipientName: String
}

protocol CareCrewInviteResolving: Sendable {
    func resolve(code: String) async throws -> ResolvedCareCrewInvite
}

enum CareCrewInviteResolutionError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            "We couldn’t find a CareCrew for that code. Check the code and try again."
        }
    }
}

/// Local MVP resolver. Replace this with your authenticated backend or CloudKit lookup.
struct DemoCareCrewInviteResolver: CareCrewInviteResolving {
    private let demoInvites: [String: String] = [
        "CARE24": "Maria",
        "MOM123": "Mom",
        "DAD123": "Dad"
    ]

    func resolve(code: String) async throws -> ResolvedCareCrewInvite {
        try await Task.sleep(for: .milliseconds(350))

        let normalizedCode = code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard let recipientName = demoInvites[normalizedCode] else {
            throw CareCrewInviteResolutionError.notFound
        }

        return ResolvedCareCrewInvite(
            code: normalizedCode,
            recipientName: recipientName
        )
    }
}
