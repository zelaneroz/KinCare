import SwiftUI

struct InviteHelperView: View {
    var onBack: () -> Void
    var onSkip: () -> Void
    var onSendInvite: () -> Void

    @State private var name: String = "Daniel"
    @State private var contact: String = ""

    var body: some View {
        VStack(spacing: 0) {
            KCProgressBar(progress: 0.86)
            KCNavHeader(title: "Who could help first?", onBack: onBack) {
                KCTextButton(title: "Skip", action: onSkip)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start with one person. You can build the circle slowly.")
                        .font(.kcSubtitle)
                        .foregroundColor(KC.muted)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    KCSectionLabel(text: "Name")
                    KCInput(placeholder: "Name", text: $name)

                    KCSectionLabel(text: "Phone or email")
                    KCInput(placeholder: "daniel@example.com", text: $contact)

                    KCSectionLabel(text: "What can Daniel see?")
                    KCCard {
                        KCMetricRow(label: "Assigned responsibilities", value: "On")
                        KCMetricRow(label: "Family updates", value: "On")
                        KCMetricRow(label: "Private medical notes", value: "Off")
                    }

                    KCNote(text: "Daniel can join through a secure link. He does not need to set up the entire app before helping.")
                        .padding(.top, 4)

                    DarkButton(title: "Send invitation", action: onSendInvite)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .background(KC.page)
    }
}

#Preview {
    InviteHelperView(onBack: {}, onSkip: {}, onSendInvite: {})
}
