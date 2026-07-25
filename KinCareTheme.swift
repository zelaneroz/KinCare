import SwiftUI

enum KinCareTheme {
    // Light, earthy palette
    static let background = Color(red: 0.969, green: 0.953, blue: 0.914)
    static let surface = Color(red: 0.996, green: 0.988, blue: 0.969)
    static let sage = Color(red: 0.333, green: 0.388, blue: 0.294)
    static let sageSoft = Color(red: 0.875, green: 0.906, blue: 0.851)
    static let terracotta = Color(red: 0.663, green: 0.373, blue: 0.278)
    static let terracottaSoft = Color(red: 0.945, green: 0.855, blue: 0.812)
    static let sand = Color(red: 0.914, green: 0.875, blue: 0.816)
    static let ink = Color(red: 0.176, green: 0.204, blue: 0.161)
    static let secondaryInk = Color(red: 0.392, green: 0.424, blue: 0.365)
    static let divider = Color(red: 0.851, green: 0.824, blue: 0.769)

    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 14
    static let pagePadding: CGFloat = 18
    static let cardShadow = Color.black.opacity(0.055)
}

extension Font {
    static let kinCareHero = Font.system(.title, design: .rounded, weight: .bold)
    static let kinCareTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let kinCareHeadline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let kinCareBody = Font.system(.body, design: .rounded)
    static let kinCareCaption = Font.system(.caption, design: .rounded, weight: .medium)
}

private struct KinCarePageModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .fontDesign(.rounded)
            .foregroundStyle(KinCareTheme.ink)
            .tint(KinCareTheme.sage)
    }
}

private struct KinCareCardModifier: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                KinCareTheme.surface,
                in: RoundedRectangle(
                    cornerRadius: KinCareTheme.cardRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: KinCareTheme.cardRadius,
                    style: .continuous
                )
                .stroke(KinCareTheme.divider.opacity(0.6), lineWidth: 0.7)
            }
            .shadow(
                color: KinCareTheme.cardShadow,
                radius: 14,
                x: 0,
                y: 6
            )
    }
}

extension View {
    func kinCarePageStyle() -> some View {
        modifier(KinCarePageModifier())
    }

    func kinCareCard(padding: CGFloat = 16) -> some View {
        modifier(KinCareCardModifier(padding: padding))
    }

    func kinCareFormStyle() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(KinCareTheme.background)
            .tint(KinCareTheme.sage)
            .fontDesign(.rounded)
    }
}

struct KinCarePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                KinCareTheme.sage.opacity(configuration.isPressed ? 0.78 : 1),
                in: RoundedRectangle(
                    cornerRadius: KinCareTheme.controlRadius,
                    style: .continuous
                )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct KinCareSoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(KinCareTheme.sage)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                KinCareTheme.sageSoft.opacity(configuration.isPressed ? 0.72 : 1),
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
