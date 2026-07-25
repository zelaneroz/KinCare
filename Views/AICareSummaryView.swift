import SwiftUI
import SwiftData

struct AICareSummaryView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \CareTask.dueDate)
    private var tasks: [CareTask]

    @Query(sort: \CareRecipient.createdAt)
    private var recipients: [CareRecipient]

    @State private var selectedKind: AICareSummaryKind = .today
    @State private var summary: AICareSummary?
    @State private var isGenerating = false

    private let service: any AICareSummaryGenerating = LocalAICareSummaryService()

    private var recipientName: String {
        recipients.first?.firstName ?? "your loved one"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KinCareTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        summaryTypePicker

                        if isGenerating {
                            generatingCard
                        } else if let summary {
                            summaryCard(summary)
                            actions(summary)
                        }

                        Text("KinCare AI summarizes information already recorded in the app. Review medication details, assignments, and dates before sharing.")
                            .font(.kinCareCaption)
                            .foregroundStyle(KinCareTheme.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, KinCareTheme.pagePadding)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("AI Care Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { generate() }
            .onChange(of: selectedKind) { _ in generate() }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 13) {
            KinCareAIIcon(size: 48)

            VStack(alignment: .leading, spacing: 5) {
                KinCareAIBadge(text: "AI-generated")

                Text(selectedKind.promptTitle)
                    .font(.kinCareTitle)
                    .foregroundStyle(KinCareTheme.ink)

                Text("Create a concise update for your CareCrew without rewriting the day yourself.")
                    .font(.kinCareBody)
                    .foregroundStyle(KinCareTheme.secondaryInk)
            }
        }
    }

    private var summaryTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(AICareSummaryKind.allCases) { kind in
                    Button {
                        selectedKind = kind
                    } label: {
                        Label(kind.title, systemImage: kind.systemImage)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(selectedKind == kind ? Color.white : KinCareTheme.sage)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 10)
                            .background(
                                selectedKind == kind ? KinCareTheme.sage : KinCareTheme.sageSoft,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var generatingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("KinCare AI is preparing your summary…")
                .font(.kinCareBody)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kinCareCard()
    }

    private func summaryCard(_ summary: AICareSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(summary.opening)
                .font(.kinCareBody)
                .foregroundStyle(KinCareTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(summary.sections) { section in
                VStack(alignment: .leading, spacing: 7) {
                    Text(section.heading)
                        .font(.kinCareHeadline)

                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(KinCareTheme.sage)
                                .frame(width: 5, height: 5)
                                .padding(.top, 8)

                            Text(item)
                                .font(.kinCareBody)
                                .foregroundStyle(KinCareTheme.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if section.id != summary.sections.last?.id {
                    Divider().overlay(KinCareTheme.divider)
                }
            }

            Text("Generated \(summary.generatedAt.formatted(date: .omitted, time: .shortened))")
                .font(.kinCareCaption)
                .foregroundStyle(KinCareTheme.secondaryInk)
        }
        .kinCareCard()
    }

    private func actions(_ summary: AICareSummary) -> some View {
        VStack(spacing: 10) {
            ShareLink(item: summary.shareText) {
                Label("Share with CareCrew", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(KinCarePrimaryButtonStyle())

            Button {
                generate()
            } label: {
                Label("Generate again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(KinCareSoftButtonStyle())
        }
    }

    private func generate() {
        isGenerating = true

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(260))
            summary = service.generate(
                kind: selectedKind,
                tasks: tasks,
                recipientName: recipientName,
                now: .now
            )
            isGenerating = false
        }
    }
}
