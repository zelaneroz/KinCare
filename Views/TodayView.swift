import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CareTask.dueDate)
    private var tasks: [CareTask]

    @Query(sort: \CareMember.createdAt)
    private var members: [CareMember]

    @Query(sort: \CapacityCheckIn.date, order: .reverse)
    private var checkIns: [CapacityCheckIn]

    @Query(sort: \CareRecipient.createdAt)
    private var recipients: [CareRecipient]

    @State private var showingAddTask = false
    @State private var showingCareSummary = false
    @State private var isCareSummaryExpanded = false
    @State private var showingHelpComposer = false
    @State private var selectedInsightItem: CareInsightItem?

    private var openTodayTasks: [CareTask] {
        tasks.filter {
            !$0.isCompleted &&
            (Calendar.current.isDateInToday($0.dueDate) || $0.dueDate < .now)
        }
    }

    private var insight: CareInsightDigest? {
        InsightEngine.makeInsight(
            tasks: tasks,
            members: members,
            checkIns: checkIns
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KinCareTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        header

                        if let insight {
                            InsightCard(insight: insight) { item in
                                selectedInsightItem = item
                                showingHelpComposer = true
                            }
                        }

                        careSummaryCard
                        todaySection
                    }
                    .padding(.horizontal, KinCareTheme.pagePadding)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showingCareSummary) {
                AICareSummaryView()
            }
            .sheet(isPresented: $showingHelpComposer) {
                HelpRequestComposerView(
                    helperName: selectedInsightItem?.suggestedMemberName,
                    taskTitle: selectedInsightItem?.suggestedTaskTitle
                )
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 13) {
            VStack(alignment: .leading, spacing: 7) {
                Text(greeting)
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.secondaryInk)
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text("Care for \(recipients.first?.firstName ?? "your loved one"),\nwithout carrying it alone.")
                    .font(.kinCareHero)
                    .foregroundStyle(KinCareTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(KinCareTheme.sage)
                    .frame(width: 48, height: 48)

                Image(systemName: "heart.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 19, weight: .semibold))
            }
            .accessibilityHidden(true)
        }
    }

    private var careSummaryCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCareSummaryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 11) {
                    KinCareAIBadge(text: "AI summary")

                    Text("Care summaries")
                        .font(.kinCareHeadline)
                        .foregroundStyle(KinCareTheme.ink)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(KinCareTheme.secondaryInk)
                        .rotationEffect(.degrees(isCareSummaryExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isCareSummaryExpanded ? "Collapse care summaries" : "Expand care summaries")

            if isCareSummaryExpanded {
                VStack(alignment: .leading, spacing: 11) {
                    Divider()
                        .overlay(KinCareTheme.divider)
                        .padding(.top, 14)

                    Text("Generate what happened today, a weekly CareCrew update, upcoming care, or tasks needing follow-up.")
                        .font(.kinCareBody)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Generate summary") {
                        showingCareSummary = true
                    }
                    .buttonStyle(KinCareSoftButtonStyle())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .kinCareCard(padding: 15)
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.kinCareTitle)

                    Text("Only what needs your attention now")
                        .font(.kinCareCaption)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }

                Spacer()

                Button {
                    showingAddTask = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(KinCareSoftButtonStyle())
            }

            if openTodayTasks.isEmpty {
                VStack(spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(KinCareTheme.sageSoft)
                            .frame(width: 58, height: 58)

                        Image(systemName: "checkmark")
                            .font(.title2.bold())
                            .foregroundStyle(KinCareTheme.sage)
                    }

                    Text("Nothing urgent")
                        .font(.kinCareHeadline)

                    Text("Your open care tasks for today will appear here.")
                        .font(.kinCareBody)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .kinCareCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(openTodayTasks.enumerated()), id: \.element.id) { index, task in
                        TaskRow(task: task) {
                            toggle(task)
                        }

                        if index < openTodayTasks.count - 1 {
                            Divider()
                                .overlay(KinCareTheme.divider)
                                .padding(.vertical, 7)
                        }
                    }
                }
                .kinCareCard()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private func toggle(_ task: CareTask) {
        Task {
            await TaskCompletionService.toggle(
                task,
                among: tasks,
                in: modelContext
            )
        }
    }
}
