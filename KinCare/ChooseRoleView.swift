import SwiftUI

struct ChooseRoleView: View {
    var onBack: () -> Void
    var onContinue: () -> Void

    @State private var selected: Int = 0
    private let options: [(String, String)] = [
        ("I coordinate most of the care", "I keep track of appointments, tasks, and family updates."),
        ("I help when needed", "I want clear ways to contribute without missing requests."),
        ("I am organizing my own care", "I want trusted people involved while staying in control.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            KCNavHeader(title: "How are you helping?", onBack: onBack) {
                Color.clear.frame(width: 44, height: 44)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This only changes the setup. You can update your role later.")
                        .font(.kcSubtitle)
                        .foregroundColor(KC.muted)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    ForEach(options.indices, id: \.self) { i in
                        KCChoiceRow(
                            title: options[i].0,
                            subtitle: options[i].1,
                            selected: selected == i,
                            action: { selected = i }
                        )
                    }

                    DarkButton(title: "Continue", action: onContinue)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .background(KC.page)
    }
}

#Preview {
    ChooseRoleView(onBack: {}, onContinue: {})
}
