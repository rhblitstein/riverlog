import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator
        
        UITabBar.appearance().layer.cornerRadius = 0
        UITabBar.appearance().layer.masksToBounds = false
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("You", systemImage: "person.fill")
                }
        }
        .accentColor(Theme.primaryBlue)
    }
}
