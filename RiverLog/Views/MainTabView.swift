import SwiftUI

struct MainTabView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var selectedTab = 0
    @State private var showingLiveTracking = false

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
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            Color.clear
                .tabItem {
                    Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                    Text("Record")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("You", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(Theme.primaryBlue)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 1 {
                showingLiveTracking = true
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showingLiveTracking) {
            LiveTrackingView()
        }
    }

    private var isRecording: Bool {
        locationManager.trackingState != .idle
    }
}
