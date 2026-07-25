import SwiftUI

struct AITaskCaptureView: View {
    @Environment(\.dismiss) private var dismiss

    let members: [CareMember]
    let careRecipientName: String
    let onApply: (AITaskDraft) -> Void

    @StateObject private var speech = SpeechInputService()
    @State private var requestText = ""
    @State private var draft: AITaskDraft?
    @State private var isExtracting = false
    @State private var errorMessage: String?

    private let service: any AITaskExtracting = LocalAITaskExtractionService()

    var body: some View {
        NavigationStack {
            ZStack {
                KinCareTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        entryCard

                        if isExtracting {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("KinCare AI is organizing the task…")
                                    .font(.kinCareBody)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .kinCareCard()
                        }

                        if let draft {
                            reviewCard(draft)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.kinCareBody)
                                .foregroundStyle(KinCareTheme.terracotta)
                                .kinCareCard()
                        }

                        Text("KinCare AI suggests fields from your words. Review the date, assignee, doctor, and reminder before saving.")
                            .font(.kinCareCaption)
                            .foregroundStyle(KinCareTheme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, KinCareTheme.pagePadding)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("Create with KinCare AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speech.stopRecording()
                        dismiss()
                    }
                }
            }
            .onChange(of: speech.transcript) { newValue in
                guard !newValue.isEmpty else { return }
                requestText = newValue
            }
            .onDisappear {
                speech.stopRecording()
            }
        }
    }

    private var entryCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                KinCareAIBadge(text: "AI task creation")
                Spacer()
            }

            Text("Type or say what needs to happen")
                .font(.kinCareTitle)

            Text("Example: “Remind Alex to take Mom to Dr. Cruz next Tuesday at 2 PM.”")
                .font(.kinCareBody)
                .foregroundStyle(KinCareTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: 10) {
                TextField(
                    "Describe the care task",
                    text: $requestText,
                    axis: .vertical
                )
                .lineLimit(3...7)
                .textFieldStyle(.roundedBorder)

                Button {
                    speech.toggleRecording()
                } label: {
                    Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(
                            speech.isRecording ? KinCareTheme.terracotta : KinCareTheme.sage,
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(speech.isRecording ? "Stop dictation" : "Start dictation")
            }

            if let speechError = speech.errorMessage {
                Text(speechError)
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.terracotta)
            }

            Button {
                Task { await extract() }
            } label: {
                Label("Review AI suggestion", systemImage: "sparkles")
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
            .disabled(requestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isExtracting)
        }
        .kinCareCard()
    }

    private func reviewCard(_ draft: AITaskDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                KinCareAIBadge(text: "AI extracted")
                Spacer()
                Text("Review")
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.secondaryInk)
            }

            extractedRow("Task", value: draft.title, systemImage: "checklist")
            extractedRow("Type", value: draft.category.title, systemImage: draft.category.systemImage)
            extractedRow(
                "Assigned to",
                value: draft.assignedMemberName ?? "Unassigned",
                systemImage: "person"
            )
            extractedRow(
                "When",
                value: draft.dueDate?.formatted(date: .abbreviated, time: .shortened) ?? "Choose in task form",
                systemImage: "calendar"
            )

            if draft.category == .appointment {
                extractedRow(
                    "Doctor",
                    value: draft.doctorName.map { "Dr. \($0)" } ?? "Not detected",
                    systemImage: "stethoscope"
                )

                extractedRow(
                    "Hospital or clinic",
                    value: draft.clinicName ?? "Not detected",
                    systemImage: "cross.case"
                )
            }

            extractedRow(
                "Care recipient",
                value: draft.careRecipientName,
                systemImage: "heart"
            )
            extractedRow(
                "Suggested reminder",
                value: draft.reminderDescription,
                systemImage: "bell"
            )

            Button("Use these details") {
                onApply(draft)
                dismiss()
            }
            .buttonStyle(KinCarePrimaryButtonStyle())
        }
        .kinCareCard()
    }

    private func extractedRow(
        _ label: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .foregroundStyle(KinCareTheme.sage)
                .frame(width: 23)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.secondaryInk)

                Text(value)
                    .font(.kinCareBody)
                    .foregroundStyle(KinCareTheme.ink)
            }

            Spacer(minLength: 0)
        }
    }

    @MainActor
    private func extract() async {
        isExtracting = true
        errorMessage = nil
        speech.stopRecording()

        do {
            draft = try await service.extract(
                from: requestText,
                members: members,
                careRecipientName: careRecipientName,
                now: .now
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isExtracting = false
    }
}
