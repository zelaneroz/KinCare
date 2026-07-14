import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            CircleView()
                .tabItem { Label("Circle", systemImage: "person.2") }
            YouView()
                .tabItem { Label("You", systemImage: "heart") }
        }
        .tint(KC.text)
    }
}

#Preview {
    MainTabView()
}
