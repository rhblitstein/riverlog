import SwiftUI
import CoreData
import FirebaseAuth

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthManager

    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>

    @State private var showingAddActivity = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Sticky header
                    Color(.systemBackground)
                        .frame(height: 60)
                        .overlay(
                            Text("Home")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.primaryBlue)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)

                    ScrollView {
                        VStack(spacing: 12) {
                            // Filter activities by current user
                            ForEach(activities.filter { $0.userId == authManager.user?.uid }, id: \.id) { activity in
                                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                    ActivityCardView(activity: activity)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddActivity = true }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(Theme.primaryBlue)
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
        }
    }
}
