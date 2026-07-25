import SwiftUI

struct InsightCard: View {
    let insight: CareInsightDigest
    let onAction: (CareInsightItem) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 11) {
                    KinCareAIBadge(text: "AI insight")

                    Text(insight.title)
                        .font(.kinCareHeadline)
                        .foregroundStyle(KinCareTheme.ink)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(KinCareTheme.secondaryInk)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("AI insight, \(insight.title)")
            .accessibilityHint(isExpanded ? "Collapse insight" : "Expand insight")

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()
                        .overlay(KinCareTheme.divider)
                        .padding(.top, 14)

                    ForEach(Array(insight.items.enumerated()), id: \.element.id) { index, item in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Image(systemName: item.priority == .attention ? "exclamationmark.circle.fill" : "heart.circle.fill")
                                    .foregroundStyle(item.priority == .attention ? KinCareTheme.terracotta : KinCareTheme.sage)

                                Text(item.title)
                                    .font(.kinCareHeadline)
                                    .foregroundStyle(KinCareTheme.ink)
                            }

                            Text(item.message)
                                .font(.kinCareBody)
                                .foregroundStyle(KinCareTheme.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)

                            if let actionTitle = item.actionTitle {
                                Button(actionTitle) {
                                    onAction(item)
                                }
                                .buttonStyle(KinCareSoftButtonStyle())
                                .padding(.top, 2)
                            }
                        }

                        if index < insight.items.count - 1 {
                            Divider()
                                .overlay(KinCareTheme.divider)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .kinCareCard(padding: 15)
    }
}
