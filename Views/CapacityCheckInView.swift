import SwiftUI
import SwiftData

struct CapacityCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var energy = 3
    @State private var stress = 3
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("How are you doing?") {
                    Stepper("Energy: \(energy)/5", value: $energy, in: 1...5)
                    Stepper("Stress: \(stress)/5", value: $stress, in: 1...5)

                    TextField(
                        "Anything affecting your capacity?",
                        text: $note,
                        axis: .vertical
                    )
                    .lineLimit(2...5)
                }

                Section {
                    Text("This check-in helps KinCare decide when to suggest a handoff. It is not a medical assessment.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .kinCareFormStyle()
            .navigationTitle("Capacity Check-In")
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
                    Button("Save") {
                        let checkIn = CapacityCheckIn(
                            energy: energy,
                            stress: stress,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        modelContext.insert(checkIn)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
