import SwiftUI

struct YouView: View {
    @State private var selected: Int = 1 // "I am stretched" preselected, matching the mock

    private let options: [(String, String)] = [
        ("I am doing okay", "I can manage what is planned."),
        ("I am stretched", "I could use help with one responsibility."),
        ("I am at my limit", "I need immediate practical support from my circle.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            KCHeader(eyebrow: "Private by default", title: "How are you doing?") {
                Image(systemName: "lock").font(.system(size: 18)).foregroundColor(KC.muted)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    KCBigCard(fill: KC.lav) {
                        Text("How much capacity do you have today?").font(.kcBigCardTitle).foregroundColor(KC.lavText)
                        Text("Select the answer that feels closest.").font(.kcBody).foregroundColor(KC.lavText)
                    }

                    ForEach(options.indices, id: \.self) { i in
                        KCChoiceRow(
                            title: options[i].0,
                            subtitle: options[i].1,
                            selected: selected == i,
                            accent: KC.lavText,
                            action: { selected = i }
                        )
                    }

                    LavButton(title: "Ask for practical help")
                    WhiteButton(title: "Save privately")

                    Text("KinCare will suggest a specific request. It will never share this check-in without your approval.")
                        .font(.kcFootnote)
                        .foregroundColor(KC.soft)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
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
    YouView()
}
