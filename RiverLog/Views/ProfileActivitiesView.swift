import SwiftUI
import CoreData
import FirebaseAuth

struct ProfileActivitiesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthManager

    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>

    @State private var searchText = ""

    private var userActivities: [RiverActivity] {
        let filtered = activities.filter { $0.userId == authManager.user?.uid }
        if searchText.isEmpty { return filtered }
        return filtered.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.section?.riverName ?? "").localizedCaseInsensitiveContains(searchText) ||
            ($0.section?.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Profile")
                            .font(.body)
                    }
                    .foregroundColor(.primary)
                }
                Spacer()
                Text("Activities")
                    .font(.headline)
                Spacer()
                // Balance spacer
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").opacity(0)
                    Text("Profile").opacity(0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search and filter your activities", text: $searchText)
                    .font(.subheadline)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Activity list
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(userActivities, id: \.id) { activity in
                        activityCard(activity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }

    private func activityCard(_ activity: RiverActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // User row
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(authManager.user?.displayName ?? "You")
                        .font(.subheadline).fontWeight(.semibold)
                    HStack(spacing: 4) {
                        Text(formatDate(activity.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let craft = activity.craftType, !craft.isEmpty {
                            Text("· \(craft)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Location
            if let section = activity.section {
                HStack(spacing: 4) {
                    Image(systemName: "water.waves")
                        .font(.caption)
                        .foregroundColor(Theme.primaryBlue)
                    Text("\(section.riverName ?? ""), \(section.state ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(activity.title ?? "Untitled")
                .font(.title3)
                .fontWeight(.bold)

            // Stats row
            HStack(spacing: 20) {
                statColumn(label: "Distance", value: String(format: "%.1f mi", activity.section?.mileage ?? 0))
                statColumn(label: "Class", value: activity.section?.classRating ?? "—")
                statColumn(label: "Time", value: formatDuration(activity.duration))
            }

            // Map placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 180)
                .overlay(
                    Image(systemName: "map")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                )

            // Action bar
            HStack {
                Spacer()
                Image(systemName: "hand.thumbsup")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "bubble.right")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return f.string(from: date)
    }

    private func formatDuration(_ duration: Double) -> String {
        let h = Int(duration)
        let m = Int((duration - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
