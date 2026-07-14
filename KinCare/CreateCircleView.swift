import SwiftUI

struct CreateCircleView: View {
    var onBack: () -> Void
    var onCreate: () -> Void

    @State private var name: String = "Maria"
    @State private var relationship: String = "Mother"

    var body: some View {
        VStack(spacing: 0) {
            KCProgressBar(progress: 0.32)
            KCNavHeader(title: "Who are you caring for?", onBack: onBack) {
                Color.clear.frame(width: 44, height: 44)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start with only what your family needs to recognize the circle.")
                        .font(.kcSubtitle)
                        .foregroundColor(KC.muted)
                        .padding(.top, 4)
                        .padding(.bottom, 4)

                    KCSectionLabel(text: "Preferred name")
                    KCInput(placeholder: "Name", text: $name)

                    KCSectionLabel(text: "Your relationship")
                    KCInput(placeholder: "Relationship", text: $relationship)

                    KCSectionLabel(text: "Living situation")
                    KCCard {
                        HStack(spacing: 12) {
                            Image(systemName: "house").font(.system(size: 18)).foregroundColor(KC.muted)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Lives at home").font(.kcCardTitle).foregroundColor(KC.text)
                                Text("With occasional family support").font(.kcBody).foregroundColor(KC.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.down").font(.system(size: 14)).foregroundColor(KC.muted)
                        }
                    }

                    Text("Medical history, insurance, and documents can be added later only when needed.")
                        .font(.system(size: 13))
                        .foregroundColor(KC.muted)
                        .padding(.vertical, 6)

                    DarkButton(title: "Create Maria's circle", action: onCreate)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .background(KC.page)
    }
}

#Preview {
    CreateCircleView(onBack: {}, onCreate: {})
}
