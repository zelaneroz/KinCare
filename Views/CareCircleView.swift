import SwiftUI
import SwiftData
import UIKit

struct CareCircleView: View {
    @Query(sort: \CareMember.createdAt)
    private var members: [CareMember]

    @Query(sort: \CareRecipient.createdAt)
    private var recipients: [CareRecipient]

    @Query(sort: \CareCrew.createdAt)
    private var careCrews: [CareCrew]

    @State private var showingAddMember = false

    private var lovedOneName: String {
        careCrews.first?.recipientName ??
        recipients.first?.firstName ??
        "my family member"
    }

    private var invitationCode: String {
        careCrews.first?.invitationCode ?? "KINCARE"
    }

    private var inviteURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "kincare.app"
        components.path = "/join"
        components.queryItems = [
            URLQueryItem(name: "code", value: invitationCode),
            URLQueryItem(name: "person", value: lovedOneName)
        ]

        return components.url ?? URL(string: "https://kincare.app")!
    }

    private var inviteMessage: String {
        "Hey! I’m using KinCare to make caring for \(lovedOneName) easier. Join my CareCrew so we can share tasks and stay organized together. Invitation code: \(invitationCode)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    invitationCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your CareCrew")
                            .font(.kinCareTitle)

                        Text("Keep roles simple. You can always change them later.")
                            .font(.subheadline)
                            .foregroundStyle(KinCareTheme.secondaryInk)

                        if members.isEmpty {
                            ContentUnavailableView(
                                "No one here yet",
                                systemImage: "person.2",
                                description: Text("Invite someone or add them manually.")
                            )
                            .kinCareCard()
                        } else {
                            ForEach(members) { member in
                                memberCard(member)
                            }
                        }
                    }
                }
                .padding(KinCareTheme.pagePadding)
            }
            .background(KinCareTheme.background.ignoresSafeArea())
            .kinCarePageStyle()
            .navigationTitle("CareCrew")
            .toolbarBackground(KinCareTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAddMember) {
                AddMemberView()
            }
        }
    }

    private var invitationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(KinCareTheme.sageSoft)
                    .frame(width: 52, height: 52)

                Image(systemName: "message.fill")
                    .font(.title2)
                    .foregroundStyle(KinCareTheme.sage)
            }

            Text("Care works better together")
                .font(.kinCareTitle)

            Text("Send a simple invitation through Messages or any app you already use.")
                .font(.kinCareBody)
                .foregroundStyle(KinCareTheme.secondaryInk)

            ShareLink(
                item: inviteURL,
                subject: Text("Join my KinCare CareCrew"),
                message: Text(inviteMessage)
            ) {
                Label("Invite someone", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(KinCarePrimaryButtonStyle())

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invitation code")
                        .font(.caption)
                        .foregroundStyle(KinCareTheme.secondaryInk)

                    Text(invitationCode)
                        .font(.system(.headline, design: .monospaced, weight: .semibold))
                }

                Spacer()

                Button {
                    UIPasteboard.general.string = invitationCode
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(KinCareSoftButtonStyle())
            }

            Button {
                showingAddMember = true
            } label: {
                Text("Add someone manually")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(KinCareSoftButtonStyle())

            Text("People joining with the link enter as Supporters by default. You can change their role later.")
                .font(.caption)
                .foregroundStyle(KinCareTheme.secondaryInk)
        }
        .kinCareCard()
    }

    private func memberCard(_ member: CareMember) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KinCareTheme.sageSoft)
                    .frame(width: 46, height: 46)

                Text(member.name.prefix(1).uppercased())
                    .font(.kinCareHeadline)
                    .foregroundStyle(KinCareTheme.sage)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.kinCareHeadline)

                Text(member.role.title)
                    .font(.subheadline)
                    .foregroundStyle(KinCareTheme.secondaryInk)

                if !member.relationshipToRecipient.isEmpty {
                    Text(member.relationshipToRecipient)
                        .font(.caption)
                        .foregroundStyle(KinCareTheme.secondaryInk)
                }
            }

            Spacer()

            Text(member.role.title)
                .font(.kinCareCaption)
                .foregroundStyle(KinCareTheme.sage)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(KinCareTheme.sageSoft, in: Capsule())
        }
        .kinCareCard(padding: 14)
    }
}
