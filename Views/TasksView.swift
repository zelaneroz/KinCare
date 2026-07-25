import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CareTask.dueDate)
    private var tasks: [CareTask]

    @State private var showingAddTask = false
    @State private var editingTask: CareTask?

    private var threeDayCutoff: Date {
        let calendar = Calendar.current
        let thirdDay = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: .now)) ?? .now
        return calendar.date(byAdding: DateComponents(day: 1, second: -1), to: thirdDay) ?? thirdDay
    }

    private var upcomingTasks: [CareTask] {
        tasks
            .filter { !$0.isCompleted && $0.displayDate <= threeDayCutoff }
            .sorted { $0.displayDate < $1.displayDate }
    }

    private var allOpenTasks: [CareTask] {
        tasks
            .filter { !$0.isCompleted }
            .sorted { $0.displayDate < $1.displayDate }
    }

    private var completedTasks: [CareTask] {
        tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if upcomingTasks.isEmpty {
                        Text("No care tasks due in the next three days.")
                            .foregroundStyle(KinCareTheme.secondaryInk)
                    } else {
                        ForEach(upcomingTasks) { task in
                            taskRow(task)
                        }
                    }
                } header: {
                    Text("Upcoming · Next 3 days")
                } footer: {
                    NavigationLink {
                        AllCareTasksView()
                    } label: {
                        Text(allTasksLinkTitle)
                            .font(.kinCareCaption)
                            .foregroundStyle(KinCareTheme.sage)
                    }
                    .textCase(nil)
                }

                Section("Completed") {
                    if completedTasks.isEmpty {
                        Text("Completed care tasks will appear here.")
                            .foregroundStyle(KinCareTheme.secondaryInk)
                    } else {
                        ForEach(completedTasks.prefix(10)) { task in
                            taskRow(task)
                        }
                    }
                }
            }
            .kinCareFormStyle()
            .navigationTitle("Care Tasks")
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add care task")
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $editingTask) { task in
                AddTaskView(task: task)
            }
        }
    }

    private var allTasksLinkTitle: String {
        let hiddenCount = max(allOpenTasks.count - upcomingTasks.count, 0)
        if hiddenCount > 0 {
            return "Show all care tasks · \(hiddenCount) later"
        }
        return "Show all care tasks"
    }

    @ViewBuilder
    private func taskRow(_ task: CareTask) -> some View {
        TaskRow(task: task) {
            Task {
                await TaskCompletionService.toggle(
                    task,
                    among: tasks,
                    in: modelContext
                )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingTask = task
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                editingTask = task
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(KinCareTheme.sage)
        }
        .listRowBackground(KinCareTheme.surface)
    }
}
