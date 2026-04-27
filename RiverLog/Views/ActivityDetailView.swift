import SwiftUI
import CoreData
import FirebaseAuth

struct ActivityDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingComingSoon = false

    let activity: RiverActivity

    func craftIcon(for craftType: String) -> String {
        switch craftType {
        case "Raft": return "🚣"
        case "Kayak": return "🛶"
        case "SUP": return "🏄"
        case "Canoe": return "🛶"
        case "Cat": return "😸"
        case "Duckie": return "🦆"
        case "IK": return "🎒"
        default: return "🌊"
        }
    }

    var formattedDateTime: String {
        guard let date = activity.date else { return "" }
        let calendar = Calendar.current
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "h:mm a"
        let time = timeFmt.string(from: date)
        if calendar.isDateInToday(date) {
            return "Today at \(time)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday at \(time)"
        } else {
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "MMM d"
            return "\(dateFmt.string(from: date)) at \(time)"
        }
    }

    var photos: [UIImage] {
        if let photoDataArray = activity.photoData as? [Data] {
            return photoDataArray.compactMap { UIImage(data: $0) }
        }
        return []
    }

    func formatClassRating(_ rating: String) -> String {
        var formatted = rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "standout", with: "(")
        if formatted.contains("(") && !formatted.contains(")") {
            formatted += ")"
        }
        return formatted
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top bar
                topBar

                Divider()

                // User row
                userRow

                // Title
                Text(activity.title ?? "Untitled")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)

                // Notes
                if !activity.hideNotes, let notes = activity.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }

                // Trip report
                if let tripReport = activity.tripReport, !tripReport.isEmpty {
                    Text(tripReport)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }

                // Stats grid
                statsGrid
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Gear row
                gearRow
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Kudos / comments placeholder
                HStack {
                    Text("0 kudos")
                        .font(.caption)
                        .foregroundColor(Theme.primaryBlue)
                    Spacer()
                    Text("0 comments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // Action bar
                Divider().padding(.top, 4)
                actionBar

                // Section info card
                if let section = activity.section {
                    Divider()
                    sectionInfoCard(section)
                }

                // Photos
                if !activity.hidePhotos, !photos.isEmpty {
                    Divider()
                        .padding(.top, 4)
                    photoSection
                }

                // GPS Route
                if activity.hasGPSData {
                    Divider()
                        .padding(.vertical, 8)
                    gpsSection
                }

                // Private notes
                if let privateNotes = activity.privateNotes, !privateNotes.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Private Notes")
                                .font(.headline)
                        }
                        Text(privateNotes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(12)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                }

                // Visibility
                HStack(spacing: 4) {
                    Image(systemName: visibilityIcon)
                        .font(.caption2)
                    Text(visibilityText)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            EditActivityView(activity: activity)
        }
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteActivity() }
        } message: {
            Text("Are you sure you want to delete this activity? This cannot be undone.")
        }
        .alert("Coming Soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Spacer()
            Text(activity.craftType ?? "Activity")
                .font(.headline)
            Spacer()
            HStack(spacing: 16) {
                Button { showingComingSoon = true } label: {
                    Image(systemName: "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                Menu {
                    Button { showingEditSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - User Row

    private var userRow: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(authManager.user?.displayName ?? "You")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(formattedDateTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let section = activity.section {
                    HStack(spacing: 4) {
                        Text(craftIcon(for: activity.craftType ?? ""))
                            .font(.system(size: 11))
                        Text("\(section.riverName ?? "") - \(section.name ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let section = activity.section
        let h = Int(activity.duration)
        let m = Int((activity.duration - Double(h)) * 60)

        return VStack(spacing: 0) {
            statRow(
                left: ("Distance", section != nil && section!.mileage > 0 ? String(format: "%.1f mi", section!.mileage) : "-"),
                right: ("Class", section?.classRating != nil ? formatClassRating(section!.classRating!) : "-")
            )
            Divider().padding(.horizontal, 4)
            statRow(
                left: ("Elapsed Time", activity.duration > 0 && !activity.hideDuration ? "\(h)h \(m)m" : "-"),
                right: ("Flow", !activity.hideFlow && activity.flowValue > 0 ? "\(Int(activity.flowValue)) \(activity.flowUnit ?? "CFS")" : "-")
            )
            Divider().padding(.horizontal, 4)
            statRow(
                left: ("Gradient", section != nil && section!.gradient > 0 ? "\(Int(section!.gradient)) ft/mi" : "-"),
                right: ("Trip Type", activity.tripType ?? "-")
            )
        }
    }

    private func statRow(left: (String, String), right: (String, String)) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(left.0).font(.caption).foregroundColor(.secondary)
                Text(left.1).font(.title3).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            Divider().frame(height: 36)

            VStack(spacing: 4) {
                Text(right.0).font(.caption).foregroundColor(.secondary)
                Text(right.1).font(.title3).fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Gear Row

    private var gearRow: some View {
        VStack(spacing: 0) {
            Divider().padding(.horizontal, 4)
            HStack(spacing: 10) {
                Text(craftIcon(for: activity.gear?.craftType ?? activity.craftType ?? ""))
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gear")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(gearLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .padding(.vertical, 10)
        }
    }

    private var gearLabel: String {
        if let gear = activity.gear {
            var parts: [String] = []
            if let name = gear.name, !name.isEmpty { parts.append(name) }
            if let brand = gear.brand, !brand.isEmpty {
                if let model = gear.model, !model.isEmpty {
                    parts.append("\(brand) \(model)")
                } else {
                    parts.append(brand)
                }
            }
            return parts.isEmpty ? (gear.craftType ?? "Unknown") : parts.joined(separator: " · ")
        }
        return activity.craftType ?? "Unknown craft"
    }

    // MARK: - Section Info Card

    private func sectionInfoCard(_ section: RiverSection) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "water.waves")
                .font(.title2)
                .foregroundColor(Theme.primaryBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(section.riverName ?? "") - \(section.name ?? "")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let state = section.state, !state.isEmpty {
                    Text(state)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.systemGray3))
        }
        .padding(16)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Spacer()
            Button { showingComingSoon = true } label: {
                Image(systemName: "hand.thumbsup")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { showingComingSoon = true } label: {
                Image(systemName: "bubble.right")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { showingComingSoon = true } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Photos

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if photos.count == 1 {
                Image(uiImage: photos[0])
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipped()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos.indices, id: \.self) { i in
                            Image(uiImage: photos[i])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 250)
                                .clipped()
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - GPS

    private var gpsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.headline)
                .padding(.horizontal, 16)

            RouteMapView(activity: activity)

            if activity.totalDistance > 0 || activity.elevationGain > 0 {
                HStack(spacing: 24) {
                    if activity.totalDistance > 0 {
                        VStack(spacing: 2) {
                            Text("GPS Distance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f mi", activity.totalDistance / 1609.34))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                    if activity.elevationGain > 0 {
                        VStack(spacing: 2) {
                            Text("Elev. Gain")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f ft", activity.elevationGain * 3.281))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                    if activity.elevationLoss > 0 {
                        VStack(spacing: 2) {
                            Text("Elev. Drop")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f ft", activity.elevationLoss * 3.281))
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Visibility

    var visibilityIcon: String {
        switch activity.visibility {
        case "Public": return "globe"
        case "Friends": return "person.2"
        default: return "lock"
        }
    }

    var visibilityText: String {
        switch activity.visibility {
        case "Public": return "Everyone can see this activity"
        case "Friends": return "Your friends can see this activity"
        default: return "Only you can see this activity"
        }
    }

    // MARK: - Delete

    private func deleteActivity() {
        let firestoreId = activity.firestoreId
        viewContext.delete(activity)
        do {
            try viewContext.save()
            if let firestoreId = firestoreId, !firestoreId.isEmpty {
                Task {
                    let firestoreService = FirestoreService()
                    try? await firestoreService.deleteActivityFromFirestore(firestoreId: firestoreId)
                }
            }
            dismiss()
        } catch {
            print("Error deleting activity: \(error)")
        }
    }
}

// Keep StatCard and StatCardWithEmoji for any other views that use them
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var smallerText: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(smallerText ? .subheadline : .headline).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCardWithEmoji: View {
    let emoji: String
    let label: String
    let value: String
    let color: Color
    var smallerText: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(emoji).font(.title2).frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Text(value).font(smallerText ? .subheadline : .headline).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
