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
    @State private var showingComingSoon = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top nav bar
                    HStack(spacing: 16) {
                        // Left side: profile + search
                        NavigationLink(destination: PublicProfileView()) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        }
                        Button { showingComingSoon = true } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }

                        Spacer()

                        Text("Home")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.primaryBlue)

                        Spacer()

                        // Right side: messages + alerts
                        Button { showingComingSoon = true } label: {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        Button { showingComingSoon = true } label: {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)

                    ScrollView {
                        VStack(spacing: 0) {
                            // Stats carousel
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    suggestedSectionsCard
                                    streakCard
                                    goalsCard
                                    weeklySnapshotCard
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 12)

                            ForEach(activities.filter { $0.userId == authManager.user?.uid }, id: \.id) { activity in
                                Divider()
                                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                    ActivityCardView(activity: activity, userName: authManager.user?.displayName ?? "You")
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
            .alert("Coming Soon", isPresented: $showingComingSoon) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This feature is coming soon!")
            }
        }
    }

    // MARK: - Carousel Cards

    private let cardHeight: CGFloat = 110

    private var suggestedSectionsCard: some View {
        Button { showingComingSoon = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primaryBlue)
                Text("Suggested Sections")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.black)
                Text("Discover new sections for you")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Spacer()
            }
            .frame(width: 150, height: cardHeight, alignment: .topLeading)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var streakCard: some View {
        Button { showingComingSoon = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                    Spacer()
                    Text("View calendar")
                        .font(.caption2).fontWeight(.medium)
                        .foregroundColor(Theme.primaryBlue)
                }
                Text("Your Streak")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.black)
                Text("0 weeks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Record now")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.primaryBlue)
                    .clipShape(Capsule())
            }
            .frame(width: 150, height: cardHeight, alignment: .topLeading)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var goalsCard: some View {
        Button { showingComingSoon = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    Spacer()
                    Text("Add a goal")
                        .font(.caption2).fontWeight(.medium)
                        .foregroundColor(Theme.primaryBlue)
                }
                Text("Goals")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.black)
                Text("No goals set yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(width: 150, height: cardHeight, alignment: .topLeading)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var weeklySnapshotCard: some View {
        Button { showingComingSoon = true } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                Text("Weekly Snapshot")
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
                HStack(spacing: 0) {
                    VStack(spacing: 2) {
                        Text("0")
                            .font(.callout).fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Activities")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("0 mi")
                            .font(.callout).fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Distance")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 2) {
                        Text("—")
                            .font(.callout).fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Avg Class")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 220, height: cardHeight, alignment: .topLeading)
            .padding(12)
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6), Theme.lightBlue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
