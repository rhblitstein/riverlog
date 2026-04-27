import SwiftUI

struct MainTabView: View {
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var selectedTab = 0
    @State private var showingLiveTracking = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Content area
                Group {
                    switch selectedTab {
                    case 0:
                        ContentView()
                    case 1:
                        SectionsTab()
                    case 3:
                        GroupsTab()
                    case 4:
                        ProfileView()
                    default:
                        ContentView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Custom rectangular tab bar — edge to edge, no pill
                Divider()
                HStack(spacing: 0) {
                    tabButton(icon: "house.fill", label: "Home", tag: 0, bottomInset: geo.safeAreaInsets.bottom)
                    tabButton(icon: "map", label: "Sections", tag: 1, bottomInset: geo.safeAreaInsets.bottom)
                    tabButton(icon: isRecording ? "stop.circle.fill" : "record.circle", label: "Record", tag: 2, bottomInset: geo.safeAreaInsets.bottom)
                    tabButton(icon: "person.3", label: "Groups", tag: 3, bottomInset: geo.safeAreaInsets.bottom)
                    tabButton(icon: "person.fill", label: "You", tag: 4, bottomInset: geo.safeAreaInsets.bottom)
                }
                .background(Color.white)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 2 {
                showingLiveTracking = true
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showingLiveTracking) {
            LiveTrackingView()
        }
    }

    private func tabButton(icon: String, label: String, tag: Int, bottomInset: CGFloat) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .frame(height: 20)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                Spacer().frame(height: max(bottomInset - 14, 0))
            }
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .foregroundColor(selectedTab == tag ? Theme.primaryBlue : .black)
            .background(
                selectedTab == tag
                    ? Theme.primaryBlue.opacity(0.12)
                    : Color.white
            )
        }
        .buttonStyle(.plain)
    }

    private var isRecording: Bool {
        locationManager.trackingState != .idle
    }
}
