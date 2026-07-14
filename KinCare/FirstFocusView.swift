import SwiftUI

struct FirstFocusView: View {
    var onBack: () -> Void
    var onContinue: () -> Void

    @State private var selected: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            KCProgressBar(progress: 0.5)
            KCNavHeader(title: "What would help most?", onBack: onBack) {
                Color.clear.frame(width: 44, height: 44)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose one. KinCare will keep the first screen focused on it.")
                        .font(.kcSubtitle)
                        .foregroundColor(KC.muted)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    focusOption(
                        index: 0,
                        icon: "calendar",
                        iconBg: .white,
                        iconFg: KC.blueText,
                        cardBg: selected == 0 ? KC.blue : .white,
                        title: "Know what needs attention today",
                        subtitle: "See the next appointment, task, or important change."
                    )
                    focusOption(
                        index: 1,
                        icon: "person.2",
                        iconBg: KC.sage,
                        iconFg: KC.sageText,
                        cardBg: selected == 1 ? KC.blue : .white,
                        title: "Get family members involved",
                        subtitle: "Make one clear request instead of sending multiple messages."
                    )
                    focusOption(
                        index: 2,
                        icon: "heart",
                        iconBg: KC.lav,
                        iconFg: KC.lavText,
                        cardBg: selected == 2 ? KC.blue : .white,
                        title: "Make space for myself",
                        subtitle: "Check your capacity and ask for practical relief."
                    )

                    DarkButton(title: "Continue", action: onContinue)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .background(KC.page)
    }

    @ViewBuilder
    private func focusOption(index: Int, icon: String, iconBg: Color, iconFg: Color, cardBg: Color, title: String, subtitle: String) -> some View {
        Button(action: { selected = index }) {
            HStack(spacing: 12) {
                FeatureIcon(systemIcon: icon, bg: iconBg, fg: iconFg)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.kcCardTitle).foregroundColor(KC.text)
                    Text(subtitle).font(.kcBody).foregroundColor(KC.muted)
                }
                Spacer(minLength: 0)
                if selected == index {
                    Image(systemName: "checkmark").font(.system(size: 17)).foregroundColor(KC.text)
                }
            }
            .padding(16)
        }
        .background(cardBg)
        .overlay(RoundedRectangle(cornerRadius: KC.radiusCard).stroke(selected == index ? Color.clear : KC.border, lineWidth: 0.5))
        .cornerRadius(KC.radiusCard)
        .buttonStyle(.plain)
    }
}

#Preview {
    FirstFocusView(onBack: {}, onContinue: {})
}
