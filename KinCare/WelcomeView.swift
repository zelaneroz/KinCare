import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    var onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 0) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(KC.sageText)
                    .frame(width: 64, height: 64)
                    .background(KC.sage)
                    .cornerRadius(18)
                    .padding(.bottom, 20)

                Text("Care is easier when it is shared.")
                    .font(.kcPageTitle)
                    .foregroundColor(KC.text)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)

                Text("KinCare helps your family know what matters today, who can help, and when you need support too.")
                    .font(.kcSubtitle)
                    .foregroundColor(KC.muted)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 22)

                DarkButton(title: "Get started", action: onGetStarted)
                KCTextButton(title: "I already have an account", action: onSignIn)

                Text("Private by default. You choose what others can see.")
                    .font(.kcFootnote)
                    .foregroundColor(KC.soft)
                    .padding(.top, 12)
            }
            .padding(.horizontal, 26)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KC.page)
    }
}

#Preview {
    WelcomeView(onGetStarted: {}, onSignIn: {})
}
