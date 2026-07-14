import SwiftUI

struct TodayView: View {
    var body: some View {
        VStack(spacing: 0) {
            KCHeader(eyebrow: "Good morning, Sarah", title: "Maria's care circle") {
                MiniAvatar(initials: "SL", bg: KC.blue, fg: KC.blueText)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    KCSectionLabel(text: "Today")
                    KCBigCard(fill: KC.blue) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "stethoscope").font(.system(size: 21)).foregroundColor(KC.blueText)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Neurology follow-up").font(.kcBigCardTitle).foregroundColor(KC.blueText)
                                Text("4:30 PM · Dr. Patel's office").font(.kcBody).foregroundColor(KC.blueText)
                            }
                        }
                        SmallActionButton(title: "View details")
                    }

                    HStack {
                        KCSectionLabel(text: "One thing to handle")
                        Spacer()
                        Text("See plan").font(.system(size: 13)).foregroundColor(KC.blueText)
                    }
                    KCCompactItem(
                        icon: { FeatureIcon(systemIcon: "pills", bg: KC.sage, fg: KC.sageText) },
                        title: "Pick up medication",
                        subtitle: "Daniel · due 5:00 PM",
                        trailing: { Image(systemName: "checkmark").font(.system(size: 15)).foregroundColor(KC.sageText) }
                    )

                    Color.clear.frame(height: 10)
                    KCSectionLabel(text: "Latest update")
                    KCCard {
                        HStack(alignment: .top, spacing: 12) {
                            MiniAvatar(initials: "DR", bg: KC.lav, fg: KC.lavText)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daniel · 1 hour ago").font(.kcCardTitle).foregroundColor(KC.text)
                                Text("Evening dose was lowered. The next visit is in three weeks.")
                                    .font(.kcBody).foregroundColor(KC.muted)
                            }
                        }
                    }

                    KCNote(text: "Everything else stays out of sight until it becomes relevant.")
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
    TodayView()
}
