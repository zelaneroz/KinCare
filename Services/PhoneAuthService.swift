import Foundation

protocol PhoneAuthServicing {
    var isDemoMode: Bool { get }

    func sendVerificationCode(to phoneNumber: String) async throws -> String
    func verify(code: String, verificationID: String) async throws -> Bool
}

enum PhoneAuthError: LocalizedError {
    case invalidPhoneNumber
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            "Enter a valid phone number, including the country code."
        case .invalidCode:
            "That verification code is not correct."
        }
    }
}

/// Local MVP authentication so the onboarding flow can be tested before a
/// production authentication provider is connected.
///
/// Use `123456` as the verification code.
struct DemoPhoneAuthService: PhoneAuthServicing {
    let isDemoMode = true

    func sendVerificationCode(to phoneNumber: String) async throws -> String {
        let digits = phoneNumber.filter(\.isNumber)
        guard digits.count >= 10 else {
            throw PhoneAuthError.invalidPhoneNumber
        }

        try await Task.sleep(for: .milliseconds(500))
        return UUID().uuidString
    }

    func verify(code: String, verificationID: String) async throws -> Bool {
        guard !verificationID.isEmpty else {
            throw PhoneAuthError.invalidCode
        }

        try await Task.sleep(for: .milliseconds(350))
        return code == "123456"
    }
}

#if canImport(FirebaseAuth)
import FirebaseAuth

/// Optional production adapter. Add FirebaseAuth through Swift Package Manager,
/// configure Firebase in the app, then inject this service into
/// `OnboardingFlowView` instead of `DemoPhoneAuthService`.
struct FirebasePhoneAuthService: PhoneAuthServicing {
    let isDemoMode = false

    func sendVerificationCode(to phoneNumber: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(
                phoneNumber,
                uiDelegate: nil
            ) { verificationID, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    continuation.resume(throwing: PhoneAuthError.invalidCode)
                }
            }
        }
    }

    func verify(code: String, verificationID: String) async throws -> Bool {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        _ = try await Auth.auth().signIn(with: credential)
        return true
    }
}
#endif
