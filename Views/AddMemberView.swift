import SwiftUI
import SwiftData

struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var role: CareMemberRole = .supporter

    var body: some View {
        NavigationStack {
            Form {
                Section("Person") {
                    TextField("Name", text: $name)

                    Picker("Role", selection: $role) {
                        ForEach(CareMemberRole.allCases) { role in
                            Text(role.title).tag(role)
                        }
                    }
                }

                Section {
                    Text(role.description)
                        .font(.subheadline)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }
            }
            .kinCareFormStyle()
            .navigationTitle("Add Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addMember() {
        let member = CareMember(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role
        )

        modelContext.insert(member)
        try? modelContext.save()
        dismiss()
    }
}
