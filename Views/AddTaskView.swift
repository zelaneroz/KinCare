import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CareMember.name)
    private var members: [CareMember]

    @Query(sort: \CareTask.createdAt, order: .reverse)
    private var existingTasks: [CareTask]

    @Query(sort: \CareRecipient.createdAt)
    private var recipients: [CareRecipient]

    private let task: CareTask?

    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var category: CareTaskCategory
    @State private var assignedMemberName: String
    @State private var repeatFrequency: TaskRepeatFrequency
    @State private var repeatHasEnd: Bool
    @State private var repeatEndDate: Date
    @State private var reminderEnabled: Bool
    @State private var reminderMinutesBefore: Int
    @State private var notificationRecipientNames: Set<String>
    @State private var visibility: CareTaskVisibility
    @State private var addToCalendar: Bool

    @State private var selectedPreviousMedicationName = ""
    @State private var medicationName: String
    @State private var medicationType: MedicationType
    @State private var dosageAmount: String
    @State private var medicationStartDate: Date
    @State private var medicationHasEnd: Bool
    @State private var medicationEndDate: Date
    @State private var dosageReminders: [MedicationDosageReminder]

    @State private var doctorName: String
    @State private var clinicName: String

    @State private var isSaving = false
    @State private var showingAITaskCapture = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    init(task: CareTask? = nil) {
        self.task = task

        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.taskNotes ?? "")
        _dueDate = State(initialValue: task?.dueDate ?? Date.now.addingTimeInterval(60 * 60))
        _category = State(initialValue: task?.category ?? .other)
        _assignedMemberName = State(initialValue: task?.assignedMemberName ?? "")
        _repeatFrequency = State(initialValue: task?.repeatFrequency ?? .never)
        _repeatHasEnd = State(initialValue: task?.repeatEndDate != nil)
        _repeatEndDate = State(initialValue: task?.repeatEndDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
        _reminderEnabled = State(initialValue: task?.reminderEnabled ?? true)
        _reminderMinutesBefore = State(initialValue: task?.reminderMinutesBefore ?? 30)
        _notificationRecipientNames = State(initialValue: Set(task?.notificationRecipientNames ?? ["You"]))
        _visibility = State(initialValue: task?.visibility ?? .careCircle)
        _addToCalendar = State(initialValue: task?.calendarEventIdentifier != nil)

        _medicationName = State(initialValue: task?.medicationName ?? "")
        _medicationType = State(initialValue: task?.medicationType ?? .tablet)
        _dosageAmount = State(initialValue: task?.dosageAmount ?? "")
        _medicationStartDate = State(initialValue: task?.medicationStartDate ?? .now)
        _medicationHasEnd = State(initialValue: task?.medicationEndDate != nil)
        _medicationEndDate = State(initialValue: task?.medicationEndDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now)
        _dosageReminders = State(initialValue: task?.dosageReminders ?? [])

        _doctorName = State(initialValue: task?.doctorName ?? "")
        _clinicName = State(initialValue: task?.clinicName ?? "")
    }

    private var isEditing: Bool { task != nil }

    private var previousMedications: [CareTask] {
        var seen = Set<String>()
        return existingTasks.filter { task in
            guard task.category == .medication,
                  let name = task.medicationName?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty,
                  !seen.contains(name.lowercased()) else {
                return false
            }
            seen.insert(name.lowercased())
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    aiTaskCreationSection
                }

                basicDetailsSection
                repeatSection

                if category == .medication {
                    medicationSection
                }

                if category == .appointment {
                    appointmentSection
                }

                reminderSection
                sharingSection
                calendarSection
                statusSection
            }
            .kinCareFormStyle()
            .navigationTitle(isEditing ? "Edit Care Task" : "New Care Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .sheet(isPresented: $showingAITaskCapture) {
                AITaskCaptureView(
                    members: members,
                    careRecipientName: recipients.first?.firstName ?? "your loved one"
                ) { draft in
                    applyAIDraft(draft)
                }
            }
        }
    }

    private var aiTaskCreationSection: some View {
        Section {
            Button {
                showingAITaskCapture = true
            } label: {
                HStack(spacing: 11) {
                    KinCareAIBadge(text: "AI task creation")

                    Text("Type or speak a care task")
                        .font(.kinCareHeadline)
                        .foregroundStyle(KinCareTheme.ink)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var basicDetailsSection: some View {
        Section("Care task") {
            TextField("Task name", text: $title)

            Picker("Type", selection: $category) {
                ForEach(CareTaskCategory.allCases) { category in
                    Label(category.title, systemImage: category.systemImage)
                        .tag(category)
                }
            }

            DatePicker(
                "Due",
                selection: $dueDate,
                displayedComponents: [.date, .hourAndMinute]
            )

            Picker("Assigned to", selection: $assignedMemberName) {
                Text("Unassigned").tag("")
                ForEach(members) { member in
                    Text(member.name).tag(member.name)
                }
            }

            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var repeatSection: some View {
        Section("Repeat") {
            Picker("Frequency", selection: $repeatFrequency) {
                ForEach(TaskRepeatFrequency.allCases) { frequency in
                    Text(frequency.title).tag(frequency)
                }
            }

            if repeatFrequency != .never {
                Toggle("Ends on a date", isOn: $repeatHasEnd)

                if repeatHasEnd {
                    DatePicker(
                        "Ends",
                        selection: $repeatEndDate,
                        in: dueDate...,
                        displayedComponents: .date
                    )
                }
            }
        }
    }

    private var medicationSection: some View {
        Section("Medication") {
            if !previousMedications.isEmpty {
                Picker("Use previous", selection: $selectedPreviousMedicationName) {
                    Text("Choose a medication").tag("")
                    ForEach(previousMedications, id: \.id) { medication in
                        Text(medication.medicationName ?? medication.title)
                            .tag(medication.medicationName ?? "")
                    }
                }
                .onChange(of: selectedPreviousMedicationName) { newValue in
                    applyPreviousMedication(named: newValue)
                }
            }

            TextField("Medication name", text: $medicationName)

            Picker("Medication type", selection: $medicationType) {
                ForEach(MedicationType.allCases) { type in
                    Text(type.title).tag(type)
                }
            }

            TextField("Amount per dosage, e.g. 10 mg", text: $dosageAmount)

            DatePicker(
                "Starts",
                selection: $medicationStartDate,
                displayedComponents: .date
            )

            Toggle("Has an end date", isOn: $medicationHasEnd)

            if medicationHasEnd {
                DatePicker(
                    "Ends",
                    selection: $medicationEndDate,
                    in: medicationStartDate...,
                    displayedComponents: .date
                )
            }
        }
    }

    private var appointmentSection: some View {
        Section("Appointment") {
            TextField("Doctor name", text: $doctorName)
            TextField("Hospital or clinic", text: $clinicName)
        }
    }

    private var reminderSection: some View {
        Section("Reminders") {
            Toggle("Enable reminders", isOn: $reminderEnabled)

            if reminderEnabled && category != .medication {
                Picker("Before", selection: $reminderMinutesBefore) {
                    Text("At due time").tag(0)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("1 day").tag(1_440)
                }
            }

            if reminderEnabled && category == .medication {
                ForEach($dosageReminders) { $reminder in
                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Reminder name", text: $reminder.name)

                        Picker("Frequency", selection: $reminder.frequency) {
                            ForEach(MedicationReminderFrequency.allCases) { frequency in
                                Text(frequency.title).tag(frequency)
                            }
                        }

                        DatePicker(
                            "Time",
                            selection: $reminder.time,
                            displayedComponents: .hourAndMinute
                        )

                        Button(role: .destructive) {
                            dosageReminders.removeAll { $0.id == reminder.id }
                        } label: {
                            Label("Remove dosage reminder", systemImage: "trash")
                        }
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    dosageReminders.append(
                        MedicationDosageReminder(
                            name: dosageReminders.isEmpty ? "Morning dose" : "Dose \(dosageReminders.count + 1)",
                            frequency: .daily,
                            time: .now
                        )
                    )
                } label: {
                    Label("Add dosage reminder", systemImage: "plus.circle")
                }
            }

            if reminderEnabled {
                Text("Send notification to")
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.secondaryInk)

                ForEach(members) { member in
                    Button {
                        toggleNotificationRecipient(member.name)
                    } label: {
                        HStack {
                            Text(member.name)
                                .foregroundStyle(KinCareTheme.ink)
                            Spacer()
                            if notificationRecipientNames.contains(member.name) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(KinCareTheme.sage)
                            }
                        }
                    }
                }

                Text("In this local MVP, reminders appear on this device. Sending them to another member’s phone requires shared care-circle sync and push notifications.")
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.secondaryInk)
            }
        }
    }

    private var sharingSection: some View {
        Section("Visibility") {
            Picker("Who can see this?", selection: $visibility) {
                ForEach(CareTaskVisibility.allCases) { visibility in
                    Text(visibility.title).tag(visibility)
                }
            }
        }
    }

    private var calendarSection: some View {
        Section("Apple Calendar") {
            if task?.calendarEventIdentifier != nil {
                Label("Added to Apple Calendar", systemImage: "calendar.badge.checkmark")
                    .foregroundStyle(KinCareTheme.sage)

                Text("KinCare will try to update the event when Calendar access allows it.")
                    .font(.kinCareCaption)
                    .foregroundStyle(KinCareTheme.secondaryInk)
            } else {
                Toggle("Add to Apple Calendar", isOn: $addToCalendar)
            }

            Text("Calendar access is requested only after you save with this option enabled.")
                .font(.kinCareCaption)
                .foregroundStyle(KinCareTheme.secondaryInk)
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        if let errorMessage {
            Section {
                Text(errorMessage)
                    .foregroundStyle(KinCareTheme.terracotta)
            }
        }

        if let successMessage {
            Section {
                Label(successMessage, systemImage: "checkmark.circle")
                    .foregroundStyle(KinCareTheme.sage)
            }
        }
    }

    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if category == .medication {
            return hasTitle &&
                !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                (!reminderEnabled || !dosageReminders.isEmpty)
        }
        return hasTitle
    }

    @MainActor
    private func save() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        let savedTask = task ?? CareTask(
            title: title,
            dueDate: dueDate
        )

        if task == nil {
            modelContext.insert(savedTask)
        }

        let previousAssignee = savedTask.assignedMemberName
        let updatedAssignee = assignedMemberName.isEmpty ? nil : assignedMemberName

        if isEditing && previousAssignee != updatedAssignee {
            savedTask.previousAssignedMemberName = previousAssignee
            savedTask.reassignmentCount = savedTask.totalReassignments + 1
        }

        savedTask.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        savedTask.taskNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        savedTask.dueDate = dueDate
        savedTask.category = category
        savedTask.assignedMemberName = updatedAssignee
        savedTask.lastModifiedAt = isEditing ? .now : savedTask.createdAt
        savedTask.repeatFrequency = repeatFrequency
        savedTask.repeatEndDate = repeatFrequency != .never && repeatHasEnd ? repeatEndDate : nil
        savedTask.reminderEnabled = reminderEnabled
        savedTask.reminderMinutesBefore = reminderMinutesBefore
        savedTask.notificationRecipientNames = Array(notificationRecipientNames).sorted()
        savedTask.visibility = visibility

        if category == .medication {
            savedTask.medicationName = medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
            savedTask.medicationType = medicationType
            savedTask.dosageAmount = dosageAmount.trimmingCharacters(in: .whitespacesAndNewlines)
            savedTask.medicationStartDate = medicationStartDate
            savedTask.medicationEndDate = medicationHasEnd ? medicationEndDate : nil
            savedTask.dosageReminders = dosageReminders
        } else {
            savedTask.medicationName = nil
            savedTask.medicationType = nil
            savedTask.dosageAmount = nil
            savedTask.medicationStartDate = nil
            savedTask.medicationEndDate = nil
            savedTask.dosageReminders = []
        }

        if category == .appointment {
            savedTask.doctorName = doctorName.trimmingCharacters(in: .whitespacesAndNewlines)
            savedTask.clinicName = clinicName.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            savedTask.doctorName = nil
            savedTask.clinicName = nil
        }

        do {
            try modelContext.save()

            if reminderEnabled {
                let granted = try await NotificationService.shared.requestAuthorization()
                if granted {
                    try await NotificationService.shared.scheduleReminders(for: savedTask)
                    try modelContext.save()
                }
            } else {
                NotificationService.shared.cancelReminders(for: savedTask)
            }

            if addToCalendar || savedTask.calendarEventIdentifier != nil {
                savedTask.calendarEventIdentifier = try await CalendarService.shared
                    .addOrUpdateCalendarEvent(for: savedTask)
                try modelContext.save()
                successMessage = "Care task saved and added to Apple Calendar."
            }

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }

    private func toggleNotificationRecipient(_ name: String) {
        if notificationRecipientNames.contains(name) {
            notificationRecipientNames.remove(name)
        } else {
            notificationRecipientNames.insert(name)
        }
    }

    private func applyAIDraft(_ draft: AITaskDraft) {
        title = draft.title
        category = draft.category
        assignedMemberName = draft.assignedMemberName ?? ""

        if let extractedDueDate = draft.dueDate {
            dueDate = extractedDueDate
        }

        reminderEnabled = true
        reminderMinutesBefore = draft.suggestedReminderMinutesBefore

        if let assignedMemberName = draft.assignedMemberName {
            notificationRecipientNames.insert(assignedMemberName)
        }

        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notes = draft.originalText
        }

        if draft.category == .appointment {
            doctorName = draft.doctorName ?? ""
            clinicName = draft.clinicName ?? ""
        }

        if draft.category == .medication && medicationName.isEmpty {
            medicationName = draft.title
        }
    }

    private func applyPreviousMedication(named name: String) {
        guard !name.isEmpty,
              let previous = previousMedications.first(where: { $0.medicationName == name }) else {
            return
        }

        medicationName = previous.medicationName ?? name
        medicationType = previous.medicationType ?? .tablet
        dosageAmount = previous.dosageAmount ?? ""
        dosageReminders = previous.dosageReminders

        if title.isEmpty {
            title = medicationName
        }
    }
}
