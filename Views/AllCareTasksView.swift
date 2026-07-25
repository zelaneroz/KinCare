import SwiftUI
import SwiftData

struct AllCareTasksView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CareTask.dueDate)
    private var tasks: [CareTask]

    @State private var editingTask: CareTask?

    private var openTasks: [CareTask] {
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
        List {
            Section("All upcoming") {
                if openTasks.isEmpty {
                    Text("No upcoming care tasks.")
                        .foregroundStyle(KinCareTheme.secondaryInk)
                } else {
                    ForEach(openTasks) { task in
                        row(task)
                    }
                }
            }

            Section("Completed") {
                if completedTasks.isEmpty {
                    Text("No completed care tasks yet.")
                        .foregroundStyle(KinCareTheme.secondaryInk)
                } else {
                    ForEach(completedTasks) { task in
                        row(task)
                    }
                }
            }
        }
        .kinCareFormStyle()
        .navigationTitle("All Care Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTask) { task in
            AddTaskView(task: task)
        }
    }

    @ViewBuilder
    private func row(_ task: CareTask) -> some View {
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
        .onTapGesture { editingTask = task }
        .listRowBackground(KinCareTheme.surface)
    }
}
