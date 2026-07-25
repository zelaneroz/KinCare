import SwiftUI

struct TaskRow: View {
    let task: CareTask
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? KinCareTheme.sage : KinCareTheme.secondaryInk)
                    .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            }
            .buttonStyle(.plain)

            ZStack {
                Circle()
                    .fill(categoryBackground)
                    .frame(width: 38, height: 38)

                Image(systemName: task.category.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(categoryForeground)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.kinCareHeadline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? KinCareTheme.secondaryInk : KinCareTheme.ink)

                if let detail = task.detailSummary {
                    Text(detail)
                        .font(.kinCareCaption)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text(task.displayDate, format: .dateTime.weekday(.abbreviated).hour().minute())

                    if task.repeatFrequency != .never {
                        Image(systemName: "repeat")
                            .accessibilityLabel("Repeats \(task.repeatFrequency.title)")
                    }

                    if let assignedMemberName = task.assignedMemberName {
                        Text("•")
                        Text(assignedMemberName)
                    }
                }
                .font(.kinCareCaption)
                .foregroundStyle(KinCareTheme.secondaryInk)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KinCareTheme.secondaryInk.opacity(0.55))
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 5)
    }

    private var categoryBackground: Color {
        task.category == .medication || task.category == .appointment
            ? KinCareTheme.terracottaSoft
            : KinCareTheme.sageSoft
    }

    private var categoryForeground: Color {
        task.category == .medication || task.category == .appointment
            ? KinCareTheme.terracotta
            : KinCareTheme.sage
    }
}
