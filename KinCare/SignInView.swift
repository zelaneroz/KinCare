import SwiftUI

struct SignInView: View {
    var onBack: () -> Void
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            KCNavHeader(title: "Welcome to KinCare", onBack: onBack) {
                Color.clear.frame(width: 44, height: 44)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose the quickest way to continue.")
                        .font(.kcSubtitle)
                        .foregroundColor(KC.muted)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    WhiteButton(title: "Continue with Apple", systemIcon: "apple.logo", action: onContinue)
                    WhiteButton(title: "Continue with Google", systemIcon: "globe", action: onContinue)
                    WhiteButton(title: "Continue with phone", systemIcon: "message", action: onContinue)
                    WhiteButton(title: "Continue with email", systemIcon: "envelope", action: onContinue)

                    Color.clear.frame(height: 8)

                    KCNote(text: "KinCare never shares your care information with family members until you invite them.")
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .background(KC.page)
    }
}

#Preview {
    SignInView(onBack: {}, onContinue: {})
}
