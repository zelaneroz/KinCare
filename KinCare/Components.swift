import SwiftUI

// MARK: - Buttons

struct DarkButton: View {
    let title: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kcButton)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .background(KC.text)
        .cornerRadius(KC.radiusControl)
    }
}

struct WhiteButton: View {
    let title: String
    var systemIcon: String? = nil
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemIcon {
                    Image(systemName: systemIcon)
                }
                Text(title).font(.kcButton)
            }
            .foregroundColor(KC.text)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: KC.radiusControl).stroke(KC.borderStrong, lineWidth: 0.5))
        .cornerRadius(KC.radiusControl)
    }
}

struct LavButton: View {
    let title: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kcButton)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .background(KC.lavBtn)
        .cornerRadius(KC.radiusControl)
    }
}

struct KCTextButton: View {
    let title: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kcButton.weight(.medium))
                .foregroundColor(KC.blueText)
                .frame(minHeight: 44)
        }
    }
}

struct SmallActionButton: View {
    let title: String
    var systemIcon: String? = nil
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemIcon { Image(systemName: systemIcon).font(.system(size: 13)) }
                Text(title).font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(KC.text)
            .padding(.horizontal, 13)
            .frame(minHeight: 40)
        }
        .background(Color.white)
        .cornerRadius(10)
    }
}

// MARK: - Icon button (44x44 tap target)

struct KCIconButton: View {
    let systemIcon: String
    let accessibilityLabel: String
    var action: () -> Void = {}
    var body: some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: 19))
                .foregroundColor(KC.text)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Header

struct KCHeader<Trailing: View>: View {
    var eyebrow: String? = nil
    var title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow).font(.kcMetadata).foregroundColor(KC.muted)
                }
                Text(title).font(.kcHeaderTitle).foregroundColor(KC.text)
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 13)
        .background(KC.band)
        .overlay(Rectangle().fill(KC.border).frame(height: 0.5), alignment: .bottom)
    }
}

/// Header with a leading back button and optional trailing view — used on onboarding screens.
struct KCNavHeader<Trailing: View>: View {
    let title: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            if let onBack {
                KCIconButton(systemIcon: "chevron.left", accessibilityLabel: "Go back", action: onBack)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            Spacer()
            Text(title).font(.kcHeaderTitle).foregroundColor(KC.text)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 6)
        .padding(.top, 14)
        .padding(.bottom, 13)
        .background(KC.band)
        .overlay(Rectangle().fill(KC.border).frame(height: 0.5), alignment: .bottom)
    }
}

// MARK: - Progress bar (onboarding)

struct KCProgressBar: View {
    let progress: Double // 0...1
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: "EAE4D9"))
                Capsule().fill(KC.sageText).frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .accessibilityElement()
        .accessibilityLabel("Setup progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

// MARK: - Cards

struct KCCard<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 4, content: content)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: KC.radiusCard).stroke(KC.border, lineWidth: 0.5))
            .cornerRadius(KC.radiusCard)
    }
}

struct KCBigCard<Content: View>: View {
    let fill: Color
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 4, content: content)
            .padding(18)
            .background(fill)
            .cornerRadius(KC.radiusCard)
    }
}

// MARK: - Feature icon (colored square)

struct FeatureIcon: View {
    let systemIcon: String
    let bg: Color
    let fg: Color
    var body: some View {
        Image(systemName: systemIcon)
            .font(.system(size: 17))
            .foregroundColor(fg)
            .frame(width: 38, height: 38)
            .background(bg)
            .cornerRadius(12)
    }
}

// MARK: - Mini avatar

struct MiniAvatar: View {
    let initials: String
    let bg: Color
    let fg: Color
    var body: some View {
        Text(initials)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(fg)
            .frame(width: 34, height: 34)
            .background(bg)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - Radio choice row (tappable)

struct KCChoiceRow: View {
    let title: String
    let subtitle: String
    let selected: Bool
    var accent: Color = KC.sageText
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .strokeBorder(selected ? accent : Color(hex: "A69D92"), lineWidth: selected ? 6 : 1.5)
                    .frame(width: 20, height: 20)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.kcCardTitle).foregroundColor(KC.text)
                    Text(subtitle).font(.kcBody).foregroundColor(KC.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: KC.radiusCard).stroke(selected ? accent : KC.borderStrong, lineWidth: selected ? 1 : 0.5))
        .cornerRadius(KC.radiusCard)
        .buttonStyle(.plain)
    }
}

// MARK: - Compact list item

struct KCCompactItem<Leading: View, Trailing: View>: View {
    @ViewBuilder var icon: () -> Leading
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing
    var action: (() -> Void)? = nil

    var body: some View {
        let row = HStack(spacing: 11) {
            icon()
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundColor(KC.text)
                Text(subtitle).font(.kcMetadata).foregroundColor(KC.muted)
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(minHeight: 44)
        .background(Color.white)
        .overlay(RoundedRectangle(cornerRadius: KC.radiusItem).stroke(KC.border, lineWidth: 0.5))
        .cornerRadius(KC.radiusItem)

        if let action {
            Button(action: action) { row }.buttonStyle(.plain)
        } else {
            row
        }
    }
}

// MARK: - Note box

struct KCNote: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.kcMetadata)
            .foregroundColor(KC.muted)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color(hex: "D6CFC3"), style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
    }
}

// MARK: - Metric row (used in permission summaries)

struct KCMetricRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium)).foregroundColor(KC.text)
            Spacer()
            Text(value).font(.kcMetadata).foregroundColor(KC.muted)
        }
        .padding(.vertical, 12)
        .overlay(Rectangle().fill(Color(hex: "ECE7DF")).frame(height: 0.5), alignment: .bottom)
    }
}

// MARK: - Section label

struct KCSectionLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.kcSectionLabel).foregroundColor(KC.muted)
    }
}

// MARK: - Input field

struct KCInput: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 16))
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: KC.radiusControl).stroke(KC.borderStrong, lineWidth: 0.5))
            .cornerRadius(KC.radiusControl)
    }
}

// MARK: - Bottom tab bar (custom, matches HTML mock)
// Only needed if you don't use SwiftUI's native TabView chrome — see MainTabView.swift.

struct KCTabBarItem: View {
    let systemIcon: String
    let label: String
    let active: Bool
    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemIcon).font(.system(size: 19))
            Text(label).font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(active ? KC.text : KC.muted)
        .frame(minWidth: 76, minHeight: 52)
        .overlay(Rectangle().fill(active ? KC.text : .clear).frame(height: 2), alignment: .top)
    }
}
