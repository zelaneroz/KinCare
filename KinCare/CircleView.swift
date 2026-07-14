import SwiftUI

struct CircleView: View {
    var onInvite: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            KCHeader(eyebrow: "Maria's care circle", title: "Your people") {
                KCIconButton(systemIcon: "person.badge.plus", accessibilityLabel: "Invite someone new", action: onInvite)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    KCSectionLabel(text: "Needs help")
                    KCBigCard(fill: KC.sage) {
                        Text("Saturday afternoon coverage").font(.kcBigCardTitle).foregroundColor(KC.sageText)
                        Text("Sarah needs three hours away from caregiving.").font(.kcBody).foregroundColor(KC.sageText)
                        SmallActionButton(title: "Ask the circle")
                    }

                    KCSectionLabel(text: "People")
                    VStack(spacing: 8) {
                        KCCompactItem(
                            icon: { MiniAvatar(initials: "SL", bg: KC.blue, fg: KC.blueText) },
                            title: "Sarah",
                            subtitle: "Coordinator · 3 items this week",
                            trailing: { EmptyView() }
                        )
                        KCCompactItem(
                            icon: { MiniAvatar(initials: "DR", bg: KC.lav, fg: KC.lavText) },
                            title: "Daniel",
                            subtitle: "Care partner · 1 item this week",
                            trailing: { EmptyView() }
                        )
                        KCCompactItem(
                            icon: { MiniAvatar(initials: "AM", bg: KC.sage, fg: KC.sageText) },
                            title: "Ana",
                            subtitle: "Family helper · available weekends",
                            trailing: { EmptyView() }
                        )
                    }

                    Color.clear.frame(height: 10)
                    KCSectionLabel(text: "Recent activity")
                    KCCard {
                        (Text("Daniel").font(.system(size: 14, weight: .medium)).foregroundColor(KC.text)
                            + Text(" completed the pharmacy pickup.").font(.kcBody).foregroundColor(KC.muted))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 12)
            }
        }
        .background(KC.page)
    }
}

#Preview {
    CircleView()
}
