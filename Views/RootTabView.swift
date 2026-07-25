import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }

            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            CareCircleView()
                .tabItem {
                    Label("Circle", systemImage: "person.3.fill")
                }

            CaregiverView()
                .tabItem {
                    Label("You", systemImage: "heart.fill")
                }
        }
        .tint(KinCareTheme.sage)
        .toolbarBackground(KinCareTheme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
