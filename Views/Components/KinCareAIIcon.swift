import SwiftUI

struct KinCareAIIcon: View {
    var size: CGFloat = 34
    var accent: Color = KinCareTheme.sage
    var background: Color = KinCareTheme.sageSoft

    var body: some View {
        ZStack {
            Circle()
                .fill(background)

            Image(systemName: "diamond.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(accent)

            Image(systemName: "sparkles")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(accent)
                .offset(x: size * 0.27, y: -size * 0.25)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("KinCare AI")
    }
}

struct KinCareAIBadge: View {
    var text: String = "KinCare AI"

    var body: some View {
        HStack(spacing: 7) {
            KinCareAIIcon(size: 22)

            Text(text)
                .font(.kinCareCaption)
                .foregroundStyle(KinCareTheme.sage)
        }
        .padding(.trailing, 10)
        .background(KinCareTheme.sageSoft.opacity(0.72), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
