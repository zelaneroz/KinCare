import SwiftUI

struct OnboardingFlow: View {
    var onFinished: () -> Void

    enum Step: Hashable {
        case signIn, chooseRole, createCircle, firstFocus, addFirstItem, inviteHelper
    }

    @State private var path: [Step] = []

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onGetStarted: { path.append(.chooseRole) },
                onSignIn: { path.append(.signIn) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .signIn:
                    SignInView(
                        onBack: { path.removeLast() },
                        onContinue: { path.append(.chooseRole) }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .chooseRole:
                    ChooseRoleView(
                        onBack: { path.removeLast() },
                        onContinue: { path.append(.createCircle) }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .createCircle:
                    CreateCircleView(
                        onBack: { path.removeLast() },
                        onCreate: { path.append(.firstFocus) }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .firstFocus:
                    FirstFocusView(
                        onBack: { path.removeLast() },
                        onContinue: { path.append(.addFirstItem) }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .addFirstItem:
                    AddFirstItemView(
                        onBack: { path.removeLast() },
                        onChooseType: { path.append(.inviteHelper) }
                    )
                    .toolbar(.hidden, for: .navigationBar)

                case .inviteHelper:
                    InviteHelperView(
                        onBack: { path.removeLast() },
                        onSkip: onFinished,
                        onSendInvite: onFinished
                    )
                    .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
    }
}

#Preview {
    OnboardingFlow(onFinished: {})
}
