import SwiftUI
import CoreData
import FirebaseAuth

struct ProfileStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthManager

    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>

    @State private var selectedFilter = 0
    let filterLabels = ["All", "Raft", "Kayak"]

    private var userActivities: [RiverActivity] {
        let all = activities.filter { $0.userId == authManager.user?.uid }
        switch selectedFilter {
        case 1: return all.filter { $0.craftType == "Raft" }
        case 2: return all.filter { $0.craftType == "Kayak" }
        default: return all
        }
    }

    private var ytdActivities: [RiverActivity] {
        let yearStart = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date()))!
        return userActivities.filter { ($0.date ?? .distantPast) >= yearStart }
    }

    private var weeksActive: Double {
        guard let first = userActivities.compactMap({ $0.date }).min() else { return 1 }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: first, to: Date()).weekOfYear ?? 1
        return max(Double(weeks), 1)
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
                Text("Statistics")
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").opacity(0)
                    Text("Profile").opacity(0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Segmented filter
            Picker("Filter", selection: $selectedFilter) {
                ForEach(0..<filterLabels.count, id: \.self) { i in
                    Text(filterLabels[i]).tag(i)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    // ACTIVITY
                    sectionHeader("ACTIVITY")
                    statRow("Avg Activities/Week", value: String(format: "%.1f", Double(userActivities.count) / weeksActive))
                    Divider().padding(.leading, 16)
                    statRow("Avg Time/Week", value: formatHours(userActivities.reduce(0) { $0 + $1.duration } / weeksActive))
                    Divider().padding(.leading, 16)
                    statRow("Avg Distance/Week", value: String(format: "%.0f mi", userActivities.reduce(0) { $0 + ($1.section?.mileage ?? 0) } / weeksActive))

                    // YEAR-TO-DATE
                    sectionHeader("YEAR-TO-DATE")
                    statRow("Activities", value: "\(ytdActivities.count)")
                    Divider().padding(.leading, 16)
                    statRow("Time", value: formatHours(ytdActivities.reduce(0) { $0 + $1.duration }))
                    Divider().padding(.leading, 16)
                    statRow("Distance", value: String(format: "%.0f mi", ytdActivities.reduce(0) { $0 + ($1.section?.mileage ?? 0) }))
                    Divider().padding(.leading, 16)
                    statRow("Avg Class", value: mostCommonClass(ytdActivities))

                    // ALL TIME
                    sectionHeader("ALL TIME")
                    statRow("Activities", value: "\(userActivities.count)")
                    Divider().padding(.leading, 16)
                    statRow("Distance", value: String(format: "%.0f mi", userActivities.reduce(0) { $0 + ($1.section?.mileage ?? 0) }))
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    private func mostCommonClass(_ acts: [RiverActivity]) -> String {
        let classes = acts.compactMap { $0.section?.classRating }
        guard !classes.isEmpty else { return "—" }
        let counts = Dictionary(grouping: classes, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }
}
