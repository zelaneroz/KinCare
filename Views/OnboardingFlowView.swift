import SwiftUI
import SwiftData
import Combine
import UIKit

@MainActor
final class OnboardingDraft: ObservableObject {
    @Published var phoneNumber = ""
    @Published var verificationCode = ""
    @Published var firstName = ""
    @Published var lastName = ""

    @Published var recipientName = ""
    @Published var selectedHealthConditions = Set<HealthCondition>()
    @Published var zipCode = ""
    @Published var healthInsurance = ""
    @Published var creatorRole: CareMemberRole = .caregiver
    @Published var contextFirstResponse = ""
    @Published var contextSecondResponse = ""

    @Published var invitationCode = ""
    @Published var relationshipToRecipient: CareRelationship?
    @Published var selectedAvailabilitySlots = Set<WeeklyAvailabilitySlot>()
    @Published var preferredTaskCategories = Set<CareTaskCategory>()

    let startedFromInviteLink: Bool

    init(invite: KinCareInvite?) {
        self.startedFromInviteLink = invite != nil
        self.invitationCode = invite?.code ?? ""
        self.recipientName = invite?.recipientName ?? ""
    }

    var fullName: String {
        "\(firstName) \(lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum OnboardingStep {
    case phone
    case verification
    case name
    case choosePath
    case createCareCrew
    case contextOne
    case contextTwo
    case joinCode
    case joinDetails
}

struct OnboardingFlowView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var draft: OnboardingDraft
    @State private var step: OnboardingStep = .phone
    @State private var verificationID = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    private let authService: any PhoneAuthServicing
    private let inviteResolver: any CareCrewInviteResolving

    init(
        prefilledInvite: KinCareInvite?,
        authService: any PhoneAuthServicing = DemoPhoneAuthService(),
        inviteResolver: any CareCrewInviteResolving = DemoCareCrewInviteResolver()
    ) {
        _draft = StateObject(
            wrappedValue: OnboardingDraft(invite: prefilledInvite)
        )
        self.authService = authService
        self.inviteResolver = inviteResolver
    }

    var body: some View {
        NavigationStack {
            OnboardingShell(
                progress: progress,
                errorMessage: errorMessage
            ) {
                stepContent
            }
            .toolbar {
                if step != .phone {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            goBack()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
            }
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .phone:
            phoneStep
        case .verification:
            verificationStep
        case .name:
            nameStep
        case .choosePath:
            choosePathStep
        case .createCareCrew:
            createCareCrewStep
        case .contextOne:
            contextOneStep
        case .contextTwo:
            contextTwoStep
        case .joinCode:
            joinCodeStep
        case .joinDetails:
            joinDetailsStep
        }
    }

    private var phoneStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingHeader(
                icon: "phone.fill",
                title: "Welcome to KinCare",
                subtitle: "Start with your phone number so your CareCrew can recognize you."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Phone number")
                    .font(.kinCareHeadline)

                TextField("+1 216 555 0123", text: $draft.phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .padding(14)
                    .background(KinCareTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(KinCareTheme.divider, lineWidth: 0.8)
                    }
            }

            Button {
                Task { await sendVerificationCode() }
            } label: {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Send verification code")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(
                isWorking ||
                draft.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )

            Text("Message and data rates may apply. KinCare uses your number only for account access and CareCrew invitations.")
                .font(.caption)
                .foregroundStyle(KinCareTheme.secondaryInk)
        }
    }

    private var verificationStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingHeader(
                icon: "checkmark.shield.fill",
                title: "Verify your number",
                subtitle: "Enter the six-digit code sent to \(draft.phoneNumber)."
            )

            TextField("000000", text: $draft.verificationCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(.title2, design: .monospaced, weight: .semibold))
                .padding(16)
                .background(KinCareTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(KinCareTheme.divider, lineWidth: 0.8)
                }
                .onChange(of: draft.verificationCode) { _, newValue in
                    draft.verificationCode = String(
                        newValue.filter(\.isNumber).prefix(6)
                    )
                }

            if authService.isDemoMode {
                Label(
                    "Local MVP code: 123456",
                    systemImage: "hammer.fill"
                )
                .font(.caption)
                .foregroundStyle(KinCareTheme.terracotta)
            }

            Button {
                Task { await verifyCode() }
            } label: {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Verify and continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(isWorking || draft.verificationCode.count != 6)

            Button("Send another code") {
                Task { await sendVerificationCode() }
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(KinCareTheme.sage)
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingHeader(
                icon: "person.crop.circle.fill",
                title: "What should your CareCrew call you?",
                subtitle: "Use the name your family and supporters will recognize."
            )

            VStack(spacing: 14) {
                LabeledTextField(
                    label: "First name",
                    placeholder: "First name",
                    text: $draft.firstName,
                    contentType: .givenName
                )

                LabeledTextField(
                    label: "Last name",
                    placeholder: "Last name",
                    text: $draft.lastName,
                    contentType: .familyName
                )
            }

            Button {
                if draft.startedFromInviteLink {
                    Task { await continueFromInviteLink() }
                } else {
                    errorMessage = nil
                    step = .choosePath
                }
            } label: {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(
                draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    private var choosePathStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingHeader(
                icon: "person.3.fill",
                title: "Create or join a CareCrew",
                subtitle: "A CareCrew is the small group helping one person receive care."
            )

            ChoiceCard(
                icon: "plus.circle.fill",
                title: "Create a new CareCrew",
                description: "Set up care for a family member and invite others when you are ready."
            ) {
                errorMessage = nil
                step = .createCareCrew
            }

            ChoiceCard(
                icon: "link.circle.fill",
                title: "Join a CareCrew",
                description: "Enter the invitation code shared by a family member or caregiver."
            ) {
                errorMessage = nil
                step = .joinCode
            }
        }
    }

    private var createCareCrewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(
                icon: "heart.text.clipboard.fill",
                title: "Create your CareCrew",
                subtitle: "Tell KinCare who your family is caring for. You can edit these details later."
            )

            LabeledTextField(
                label: "Person receiving care",
                placeholder: "Name",
                text: $draft.recipientName,
                contentType: .name
            )

            MultiSelectMenu(
                title: "Health conditions",
                selections: $draft.selectedHealthConditions
            )

            LabeledTextField(
                label: "ZIP code",
                placeholder: "44106",
                text: $draft.zipCode,
                keyboardType: .numberPad,
                contentType: .postalCode
            )

            LabeledTextField(
                label: "Health insurance",
                placeholder: "Provider or plan name",
                text: $draft.healthInsurance,
                contentType: nil
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Your role")
                    .font(.kinCareHeadline)

                Text(draft.fullName)
                    .font(.subheadline)
                    .foregroundStyle(KinCareTheme.secondaryInk)

                Picker("Role", selection: $draft.creatorRole) {
                    ForEach(CareMemberRole.allCases) { role in
                        Text(role.title).tag(role)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button("Talk to KinCare") {
                errorMessage = nil
                step = .contextOne
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(
                draft.recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                draft.zipCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
    }

    private var contextOneStep: some View {
        ConversationStep(
            turnLabel: "1 of 2",
            prompt: "Tell me about your typical week and what caregiving has to fit around. You can talk to me normally.",
            example: "For example: I’m a mother, I work from 9–5, and I usually help Dad before work and in the evening.",
            response: $draft.contextFirstResponse,
            buttonTitle: "Next question"
        ) {
            errorMessage = nil
            step = .contextTwo
        }
    }

    private var contextTwoStep: some View {
        ConversationStep(
            turnLabel: "2 of 2",
            prompt: "What parts of caregiving take the most energy, and what kind of help would make your week easier?",
            example: "For example: Appointments are hard during work hours. I’d like my sister to help with transportation when she is available.",
            response: $draft.contextSecondResponse,
            buttonTitle: "Create my CareCrew"
        ) {
            finishCreatingCareCrew()
        }
    }

    private var joinCodeStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            OnboardingHeader(
                icon: "number.square.fill",
                title: "Enter your invitation code",
                subtitle: "The person who invited you can find this code in their KinCare CareCrew."
            )

            TextField("ABC123", text: $draft.invitationCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(.system(.title2, design: .monospaced, weight: .semibold))
                .padding(16)
                .background(KinCareTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(KinCareTheme.divider, lineWidth: 0.8)
                }
                .onChange(of: draft.invitationCode) { _, newValue in
                    draft.invitationCode = String(
                        newValue
                            .uppercased()
                            .filter { $0.isLetter || $0.isNumber }
                            .prefix(8)
                    )
                }

            Button {
                Task { await resolveInvitationCode() }
            } label: {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Find CareCrew")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(isWorking || draft.invitationCode.count < 4)

            if inviteResolver is DemoCareCrewInviteResolver {
                Text("For local testing, try CARE24, MOM123, or DAD123.")
                    .font(.caption)
                    .foregroundStyle(KinCareTheme.secondaryInk)
            }
        }
    }

    private var joinDetailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(
                icon: "person.badge.plus",
                title: "Join \(draft.recipientName)’s CareCrew",
                subtitle: "Choose how you are connected and when you are generally able to help."
            )

            RelationshipPicker(
                recipientName: draft.recipientName,
                selection: $draft.relationshipToRecipient
            )

            WeeklyAvailabilityGrid(
                selections: $draft.selectedAvailabilitySlots
            )

            TaskPreferencePicker(
                selections: $draft.preferredTaskCategories
            )

            Button("Join \(draft.recipientName)’s CareCrew") {
                finishJoiningCareCrew()
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(
                draft.invitationCode.count < 4 ||
                draft.recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                draft.relationshipToRecipient == nil ||
                draft.selectedAvailabilitySlots.isEmpty
            )
        }
    }

    private var progress: Double {
        switch step {
        case .phone: 0.10
        case .verification: 0.22
        case .name: 0.34
        case .choosePath: 0.46
        case .createCareCrew, .joinCode: 0.60
        case .contextOne, .joinDetails: 0.76
        case .contextTwo: 0.92
        }
    }

    private func continueFromInviteLink() async {
        if !draft.recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {
            errorMessage = nil
            step = .joinDetails
            return
        }

        await resolveInvitationCode()
    }

    private func resolveInvitationCode() async {
        isWorking = true
        errorMessage = nil

        let code = draft.invitationCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        do {
            let localCrews = try modelContext.fetch(
                FetchDescriptor<CareCrew>()
            )

            if let localCrew = localCrews.first(where: {
                $0.invitationCode.uppercased() == code
            }) {
                draft.recipientName = localCrew.recipientName
            } else {
                let resolved = try await inviteResolver.resolve(code: code)
                draft.invitationCode = resolved.code
                draft.recipientName = resolved.recipientName
            }

            guard !draft.recipientName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty else {
                throw CareCrewInviteResolutionError.notFound
            }

            step = .joinDetails
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    private func sendVerificationCode() async {
        isWorking = true
        errorMessage = nil

        do {
            verificationID = try await authService.sendVerificationCode(
                to: draft.phoneNumber
            )
            draft.verificationCode = ""
            step = .verification
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    private func verifyCode() async {
        isWorking = true
        errorMessage = nil

        do {
            let verified = try await authService.verify(
                code: draft.verificationCode,
                verificationID: verificationID
            )

            guard verified else {
                throw PhoneAuthError.invalidCode
            }

            step = .name
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    private func finishCreatingCareCrew() {
        errorMessage = nil

        let invitationCode = Self.makeInvitationCode()
        let recipientName = draft.recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let profile = UserProfile(
            phoneNumber: draft.phoneNumber,
            firstName: draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            isPhoneVerified: true,
            careContextFirstResponse: draft.contextFirstResponse.trimmingCharacters(in: .whitespacesAndNewlines),
            careContextSecondResponse: draft.contextSecondResponse.trimmingCharacters(in: .whitespacesAndNewlines),
            onboardingSource: .createdCareCrew,
            currentCareCrewCode: invitationCode
        )

        let crew = CareCrew(
            name: "\(recipientName)’s CareCrew",
            invitationCode: invitationCode,
            recipientName: recipientName,
            isOwner: true
        )

        let recipient = CareRecipient(
            firstName: recipientName,
            relationship: "",
            healthConditions: Array(draft.selectedHealthConditions),
            zipCode: draft.zipCode.trimmingCharacters(in: .whitespacesAndNewlines),
            healthInsurance: draft.healthInsurance.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let member = CareMember(
            name: draft.fullName,
            role: draft.creatorRole
        )

        modelContext.insert(profile)
        modelContext.insert(crew)
        modelContext.insert(recipient)
        modelContext.insert(member)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "KinCare could not save your CareCrew. \(error.localizedDescription)"
        }
    }

    private func finishJoiningCareCrew() {
        errorMessage = nil

        let code = draft.invitationCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let recipientName = draft.recipientName
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let profile = UserProfile(
            phoneNumber: draft.phoneNumber,
            firstName: draft.firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: draft.lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            isPhoneVerified: true,
            onboardingSource: draft.startedFromInviteLink
                ? .joinedWithInviteLink
                : .joinedWithCode,
            currentCareCrewCode: code
        )

        let crew = CareCrew(
            name: "\(recipientName)’s CareCrew",
            invitationCode: code,
            recipientName: recipientName,
            isOwner: false
        )

        let relationship = draft.relationshipToRecipient?.title ?? ""
        let availabilitySlots = Array(draft.selectedAvailabilitySlots)

        let recipient = CareRecipient(
            firstName: recipientName,
            relationship: relationship
        )

        let member = CareMember(
            name: draft.fullName,
            role: .supporter,
            relationshipToRecipient: relationship,
            isAvailable: !availabilitySlots.isEmpty,
            availabilitySlots: availabilitySlots,
            preferredCategories: Array(draft.preferredTaskCategories)
        )

        modelContext.insert(profile)
        modelContext.insert(crew)
        modelContext.insert(recipient)
        modelContext.insert(member)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "KinCare could not join this CareCrew. \(error.localizedDescription)"
        }
    }

    private func goBack() {
        errorMessage = nil

        switch step {
        case .phone:
            break
        case .verification:
            step = .phone
        case .name:
            step = .verification
        case .choosePath:
            step = .name
        case .createCareCrew:
            step = .choosePath
        case .contextOne:
            step = .createCareCrew
        case .contextTwo:
            step = .contextOne
        case .joinCode:
            step = .choosePath
        case .joinDetails:
            step = draft.startedFromInviteLink ? .name : .joinCode
        }
    }

    private static func makeInvitationCode() -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).compactMap { _ in characters.randomElement() })
    }
}

private struct OnboardingShell<Content: View>: View {
    let progress: Double
    let errorMessage: String?
    let content: Content

    init(
        progress: Double,
        errorMessage: String?,
        @ViewBuilder content: () -> Content
    ) {
        self.progress = progress
        self.errorMessage = errorMessage
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProgressView(value: progress)
                    .tint(KinCareTheme.sage)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(KinCareTheme.terracotta)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            KinCareTheme.terracottaSoft,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }

                content
            }
            .padding(KinCareTheme.pagePadding)
        }
        .background(KinCareTheme.background.ignoresSafeArea())
        .kinCarePageStyle()
    }
}

private struct OnboardingHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(KinCareTheme.sageSoft)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(KinCareTheme.sage)
            }

            Text(title)
                .font(.kinCareHero)

            Text(subtitle)
                .font(.kinCareBody)
                .foregroundStyle(KinCareTheme.secondaryInk)
        }
    }
}

private struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let contentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.kinCareHeadline)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(contentType)
                .padding(14)
                .background(KinCareTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(KinCareTheme.divider, lineWidth: 0.8)
                }
        }
    }
}

private struct ChoiceCard: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(KinCareTheme.sageSoft)
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(KinCareTheme.sage)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.kinCareHeadline)
                        .foregroundStyle(KinCareTheme.ink)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(KinCareTheme.secondaryInk)
            }
            .kinCareCard()
        }
        .buttonStyle(.plain)
    }
}

private struct MultiSelectMenu: View {
    let title: String
    @Binding var selections: Set<HealthCondition>

    private var summary: String {
        if selections.isEmpty {
            return "Select one or more"
        }

        if selections.count == 1 {
            return selections.first?.title ?? "1 selected"
        }

        return "\(selections.count) selected"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.kinCareHeadline)

            Menu {
                ForEach(HealthCondition.allCases) { condition in
                    Button {
                        toggle(condition)
                    } label: {
                        Label(
                            condition.title,
                            systemImage: selections.contains(condition)
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                    }
                }
            } label: {
                HStack {
                    Text(summary)
                        .foregroundStyle(
                            selections.isEmpty
                                ? KinCareTheme.secondaryInk
                                : KinCareTheme.ink
                        )

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }
                .padding(14)
                .background(KinCareTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(KinCareTheme.divider, lineWidth: 0.8)
                }
            }
        }
    }

    private func toggle(_ condition: HealthCondition) {
        if selections.contains(condition) {
            selections.remove(condition)
        } else {
            selections.insert(condition)
        }
    }
}

private struct ConversationStep: View {
    let turnLabel: String
    let prompt: String
    let example: String
    @Binding var response: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeader(
                icon: "sparkles",
                title: "Talk to KinCare",
                subtitle: "A quick two-question conversation helps KinCare fit care around your real life."
            )

            Text("Question \(turnLabel)")
                .font(.kinCareCaption)
                .foregroundStyle(KinCareTheme.sage)

            VStack(alignment: .leading, spacing: 8) {
                Text(prompt)
                    .font(.kinCareBody)

                Text(example)
                    .font(.caption)
                    .foregroundStyle(KinCareTheme.secondaryInk)
            }
            .kinCareCard()

            TextEditor(text: $response)
                .frame(minHeight: 150)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(KinCareTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(KinCareTheme.divider, lineWidth: 0.8)
                }

            Text("KinCare stores this as caregiving context. It does not diagnose you or the person receiving care.")
                .font(.caption)
                .foregroundStyle(KinCareTheme.secondaryInk)

            Button(buttonTitle, action: action)
                .buttonStyle(KinCarePrimaryButtonStyle())
                .disabled(
                    response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
        }
    }
}

private struct RelationshipPicker: View {
    let recipientName: String
    @Binding var selection: CareRelationship?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Relationship to \(recipientName)")
                .font(.kinCareHeadline)

            Menu {
                ForEach(CareRelationship.allCases) { relationship in
                    Button {
                        selection = relationship
                    } label: {
                        Label(
                            relationship.title,
                            systemImage: selection == relationship
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                    }
                }
            } label: {
                HStack {
                    Text(selection?.title ?? "Select relationship")
                        .foregroundStyle(
                            selection == nil
                                ? KinCareTheme.secondaryInk
                                : KinCareTheme.ink
                        )

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }
                .padding(14)
                .background(
                    KinCareTheme.surface,
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(KinCareTheme.divider, lineWidth: 0.8)
                }
            }
        }
    }
}

private struct WeeklyAvailabilityGrid: View {
    @Binding var selections: Set<WeeklyAvailabilitySlot>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("General availability")
                .font(.kinCareHeadline)

            Text("Tap the times you are usually able to help. You can change this later.")
                .font(.caption)
                .foregroundStyle(KinCareTheme.secondaryInk)

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(
                    horizontalSpacing: 7,
                    verticalSpacing: 8
                ) {
                    GridRow {
                        Color.clear
                            .frame(width: 82, height: 22)

                        ForEach(CareWeekday.allCases) { day in
                            Text(day.shortTitle)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(KinCareTheme.secondaryInk)
                                .frame(width: 34)
                        }
                    }

                    ForEach(CareTimeBlock.allCases) { block in
                        GridRow {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(block.title)
                                    .font(.caption.weight(.semibold))
                                Text(block.hours)
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundStyle(KinCareTheme.secondaryInk)
                            }
                            .frame(width: 82, alignment: .leading)

                            ForEach(CareWeekday.allCases) { day in
                                availabilityButton(day: day, block: block)
                            }
                        }
                    }
                }
                .padding(12)
            }
            .background(
                KinCareTheme.surface,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(KinCareTheme.divider, lineWidth: 0.8)
            }

            Text(
                selections.isEmpty
                    ? "Select at least one time."
                    : "\(selections.count) time block\(selections.count == 1 ? "" : "s") selected"
            )
            .font(.caption)
            .foregroundStyle(
                selections.isEmpty
                    ? KinCareTheme.terracotta
                    : KinCareTheme.secondaryInk
            )
        }
    }

    private func availabilityButton(
        day: CareWeekday,
        block: CareTimeBlock
    ) -> some View {
        let slot = WeeklyAvailabilitySlot(
            weekday: day,
            timeBlock: block
        )
        let isSelected = selections.contains(slot)

        return Button {
            if isSelected {
                selections.remove(slot)
            } else {
                selections.insert(slot)
            }
        } label: {
            Image(systemName: isSelected ? "checkmark" : "plus")
                .font(.caption2.weight(.bold))
                .foregroundStyle(
                    isSelected ? Color.white : KinCareTheme.sage
                )
                .frame(width: 34, height: 34)
                .background(
                    isSelected
                        ? KinCareTheme.sage
                        : KinCareTheme.sageSoft,
                    in: RoundedRectangle(cornerRadius: 9)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(day.title), \(block.title), \(block.hours)"
        )
        .accessibilityValue(isSelected ? "Available" : "Not available")
    }
}

private struct TaskPreferencePicker: View {
    @Binding var selections: Set<CareTaskCategory>

    private let options: [CareTaskCategory] = [
        .medication,
        .appointment,
        .meal,
        .transportation,
        .household,
        .companionship,
        .other
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tasks you prefer")
                .font(.kinCareHeadline)

            Text("Choose as many as you like.")
                .font(.caption)
                .foregroundStyle(KinCareTheme.secondaryInk)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(options) { category in
                    Button {
                        toggle(category)
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: category.systemImage)
                            Text(category.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer(minLength: 0)

                            if selections.contains(category) {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(
                            selections.contains(category)
                                ? Color.white
                                : KinCareTheme.sage
                        )
                        .padding(.horizontal, 11)
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity)
                        .background(
                            selections.contains(category)
                                ? KinCareTheme.sage
                                : KinCareTheme.sageSoft,
                            in: RoundedRectangle(cornerRadius: 13)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggle(_ category: CareTaskCategory) {
        if selections.contains(category) {
            selections.remove(category)
        } else {
            selections.insert(category)
        }
    }
}
