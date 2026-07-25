import SwiftUI
import SwiftData

struct CaregiverView: View {
    @Query(sort: \CareTask.dueDate)
    private var tasks: [CareTask]

    @Query(sort: \CapacityCheckIn.date, order: .reverse)
    private var checkIns: [CapacityCheckIn]

    @AppStorage("aiSuggestionsEnabled")
    private var aiSuggestionsEnabled = true

    @State private var showingCheckIn = false

    private var completedThisWeek: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return tasks.filter {
            $0.isCompleted && ($0.completedAt ?? .distantPast) >= start
        }.count
    }

    private var completedByYouThisWeek: Int {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return tasks.filter {
            $0.isCompleted &&
            ($0.completedAt ?? .distantPast) >= start &&
            ($0.completedByName ?? $0.assignedMemberName ?? "You") == "You"
        }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Your capacity") {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(KinCareTheme.terracottaSoft)
                                .frame(width: 50, height: 50)

                            Image(systemName: "heart.text.clipboard.fill")
                                .foregroundStyle(KinCareTheme.terracotta)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tasks you completed")
                                .font(.subheadline)
                                .foregroundStyle(KinCareTheme.secondaryInk)

                            Text("\(completedByYouThisWeek) of \(completedThisWeek) this week")
                                .font(.kinCareTitle)
                        }
                    }
                    .padding(.vertical, 5)
                    .listRowBackground(KinCareTheme.surface)

                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Check in with yourself", systemImage: "waveform.path.ecg")
                    }
                    .listRowBackground(KinCareTheme.surface)
                }

                if let latest = checkIns.first {
                    Section("Latest check-in") {
                        LabeledContent("Energy", value: "\(latest.energy)/5")
                        LabeledContent("Stress", value: "\(latest.stress)/5")

                        if !latest.note.isEmpty {
                            Text(latest.note)
                                .foregroundStyle(KinCareTheme.secondaryInk)
                        }
                    }
                }

                Section {
                    Toggle("Use workload-based suggestions", isOn: $aiSuggestionsEnabled)

                    Text("Suggestions use task history, availability, and your check-ins. KinCare asks before drafting or changing anything.")
                        .font(.caption)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                } header: {
                    HStack(spacing: 7) {
                        KinCareAIIcon(size: 20)
                        Text("KinCare AI suggestions")
                    }
                }

                Section("Safety") {
                    Text("KinCare organizes care and support. It does not diagnose conditions, prescribe treatment, or replace emergency services.")
                        .font(.caption)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }
            }
            .kinCareFormStyle()
            .navigationTitle("Care for You")
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingCheckIn) {
                CapacityCheckInView()
            }
        }
    }
}
