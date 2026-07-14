import SwiftUI

struct AddFirstItemView: View {
    var onBack: () -> Void
    var onChooseType: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            KCProgressBar(progress: 0.68)
            KCNavHeader(title: "What is next?", onBack: onBack) {
                Color.clear.frame(width: 44, height: 44)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add one thing already taking up space in your mind.")
                        .font(.kcSubtitle)
                        .foregroundColor(KC.muted)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    KCBigCard(fill: KC.blue) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mic").font(.system(size: 21)).foregroundColor(KC.blueText)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Say it naturally").font(.kcBigCardTitle).foregroundColor(KC.blueText)
                                Text("\"Mom has a neurology visit Tuesday at 4:30.\"").font(.kcBody).foregroundColor(KC.blueText)
                            }
                        }
                        SmallActionButton(title: "Start speaking", systemIcon: "mic")
                    }

                    KCSectionLabel(text: "Or choose a type")

                    VStack(spacing: 8) {
                        KCCompactItem(
                            icon: { FeatureIcon(systemIcon: "calendar", bg: KC.blue, fg: KC.blueText) },
                            title: "Appointment",
                            subtitle: "Date, place, and who is going",
                            trailing: { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(KC.muted) },
                            action: onChooseType
                        )
                        KCCompactItem(
                            icon: { FeatureIcon(systemIcon: "checklist", bg: KC.sage, fg: KC.sageText) },
                            title: "Care task",
                            subtitle: "A clear responsibility someone can take",
                            trailing: { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(KC.muted) },
                            action: onChooseType
                        )
                        KCCompactItem(
                            icon: { FeatureIcon(systemIcon: "note.text", bg: KC.band, fg: KC.muted) },
                            title: "Quick update",
                            subtitle: "A short note the family may need",
                            trailing: { Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(KC.muted) },
                            action: onChooseType
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .background(KC.page)
    }
}

#Preview {
    AddFirstItemView(onBack: {}, onChooseType: {})
}
