import SwiftUI
import SwiftData

struct HelpRequestComposerView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CareMember.name)
    private var members: [CareMember]

    let taskTitle: String?

    @State private var selectedMemberName: String
    @State private var message = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingMessages = false

    private let aiService: any CareAIService = RuleBasedCareAIService()

    init(helperName: String?, taskTitle: String?) {
        self.taskTitle = taskTitle
        _selectedMemberName = State(initialValue: helperName ?? "")
    }

    private var eligibleMembers: [CareMember] {
        members.filter {
            $0.role != .viewer && $0.name != "You"
        }
    }

    private var selectedHelperName: String? {
        selectedMemberName.isEmpty ? nil : selectedMemberName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 10) {
                        KinCareAIIcon(size: 34)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI-drafted coverage request")
                                .font(.kinCareHeadline)

                            Text("Choose someone in the CareCrew, then review the message.")
                                .font(.kinCareCaption)
                                .foregroundStyle(KinCareTheme.secondaryInk)
                        }
                    }

                    Picker("Ask", selection: $selectedMemberName) {
                        Text("Choose in Messages").tag("")

                        ForEach(eligibleMembers) { member in
                            Text(member.name).tag(member.name)
                        }
                    }
                    .onChange(of: selectedMemberName) { _ in
                        Task { await generate() }
                    }

                    if isGenerating {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("KinCare AI is updating the request…")
                                .font(.kinCareCaption)
                                .foregroundStyle(KinCareTheme.secondaryInk)
                        }
                    }

                    TextEditor(text: $message)
                        .frame(minHeight: 160)

                    Text("KinCare personalizes the draft for the selected CareCrew member. In this MVP, choose their contact in Messages before sending. KinCare never sends automatically.")
                        .font(.kinCareCaption)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(KinCareTheme.terracotta)
                    }
                }

                Section {
                    if MessageComposerView.canSendText {
                        Button {
                            showingMessages = true
                        } label: {
                            Label(
                                selectedHelperName.map { "Message \($0)" } ?? "Open Messages",
                                systemImage: "message.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(KinCarePrimaryButtonStyle())
                        .disabled(message.isEmpty)
                    } else {
                        Text("Messages is unavailable in the Simulator. Test this button on a physical iPhone.")
                            .font(.kinCareCaption)
                            .foregroundStyle(KinCareTheme.secondaryInk)
                    }

                    ShareLink(item: message) {
                        Label("Share another way", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(KinCareSoftButtonStyle())
                    .disabled(message.isEmpty)
                }
            }
            .kinCareFormStyle()
            .navigationTitle("Ask for Coverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingMessages) {
                MessageComposerView(
                    recipients: [],
                    body: message
                ) {
                    showingMessages = false
                }
            }
            .task {
                if selectedMemberName.isEmpty,
                   let firstAvailable = eligibleMembers.first(where: { $0.isAvailable }) ?? eligibleMembers.first {
                    selectedMemberName = firstAvailable.name
                }
                await generate()
            }
        }
    }

    @MainActor
    private func generate() async {
        isGenerating = true
        errorMessage = nil

        do {
            message = try await aiService.draftHelpRequest(
                caregiverName: "You",
                helperName: selectedHelperName,
                taskTitle: taskTitle
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
