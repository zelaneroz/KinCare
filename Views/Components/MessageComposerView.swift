import MessageUI
import SwiftUI

struct MessageComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onFinish: () -> Void

    static var canSendText: Bool {
        MFMessageComposeViewController.canSendText()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients.isEmpty ? nil : recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(
        _ uiViewController: MFMessageComposeViewController,
        context: Context
    ) {
        uiViewController.body = body
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true)
            onFinish()
        }
    }
}
