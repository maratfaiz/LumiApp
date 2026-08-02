import SwiftUI

/// 3-tab bar (F5): Курсы / Луми / Профиль. The "Луми" tab is the visual
/// anchor and should render larger than its neighbors once the design
/// system ships a custom tab bar — using a plain TabView for now.
struct MainTabView: View {
    var body: some View {
        TabView {
            CourseListView()
                .tabItem { Label("Курсы", systemImage: "list.bullet") }

            HomeView()
                .tabItem { Label("Луми", systemImage: "star.fill") }

            ProfileView()
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .tint(LumiColor.accent)
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.makePreviewContainer())
}
