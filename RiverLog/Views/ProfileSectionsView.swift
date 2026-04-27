import SwiftUI
import CoreData
import FirebaseAuth

struct ProfileSectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthManager

    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>

    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", "Length", "Class", "State", "River"]

    private var userActivities: [RiverActivity] {
        activities.filter { $0.userId == authManager.user?.uid }
    }

    private var sectionGroups: [(section: RiverSection, count: Int)] {
        var dict: [NSManagedObjectID: (section: RiverSection, count: Int)] = [:]
        for activity in userActivities {
            guard let section = activity.section else { continue }
            let id = section.objectID
            if let existing = dict[id] {
                dict[id] = (section: existing.section, count: existing.count + 1)
            } else {
                dict[id] = (section: section, count: 1)
            }
        }

        var results = Array(dict.values)

        if !searchText.isEmpty {
            results = results.filter {
                ($0.section.name ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.section.riverName ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.section.state ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        return results.sorted { ($0.section.name ?? "") < ($1.section.name ?? "") }
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
                    }
                    .foregroundColor(.primary)
                }
                Spacer()
                Text("Sections")
                    .font(.headline)
                Spacer()
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
                TextField("Search by keyword", text: $searchText)
                    .font(.subheadline)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(filters, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            Text(filter)
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? Theme.primaryBlue : Color(.systemGray5))
                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)

            // Section list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(sectionGroups, id: \.section.objectID) { group in
                        sectionCard(group.section, count: group.count)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }

    private func sectionCard(_ section: RiverSection, count: Int) -> some View {
        HStack(spacing: 12) {
            // Map placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "map")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(section.name ?? "Unknown Section")
                    .font(.subheadline)
                    .fontWeight(.bold)

                // Class badge
                if let classRating = section.classRating, !classRating.isEmpty {
                    Text("Class \(classRating)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(classColor(classRating))
                        .cornerRadius(4)
                }

                Text(String(format: "%.1f mi", section.mileage))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let river = section.riverName, let state = section.state {
                    Text("\(river), \(state)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Ran \(count) time\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(Theme.primaryBlue)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func classColor(_ rating: String) -> Color {
        let r = rating.uppercased().replacingOccurrences(of: " ", with: "")
        if r.contains("V") && !r.hasPrefix("IV") { return .red }
        if r.hasPrefix("IV") { return .orange }
        if r.hasPrefix("III") { return Color(.systemYellow) }
        return .green
    }
}
