import SwiftUI
import CoreData
import FirebaseAuth

struct PublicProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthManager

    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>

    @State private var showingComingSoon = false
    @State private var showingQRCode = false
    @State private var showingEditProfile = false
    @State private var showingActivities = false
    @State private var showingStatistics = false
    @State private var showingSections = false
    @State private var selectedCraftFilter = "All"
    @State private var profileBio = ""
    @State private var profileCity = ""
    @State private var profileState = ""

    private let firestoreService = FirestoreService()
    let craftTypes = ["All", "Raft", "Kayak", "SUP", "Canoe", "Cat", "Duckie", "Packraft"]

    private var userActivities: [RiverActivity] {
        activities.filter { $0.userId == authManager.user?.uid }
    }

    private var filteredActivities: [RiverActivity] {
        if selectedCraftFilter == "All" {
            return userActivities
        }
        return userActivities.filter { $0.craftType == selectedCraftFilter }
    }

    private var thisWeekActivities: [RiverActivity] {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        return filteredActivities.filter { activity in
            guard let date = activity.date else { return false }
            return date >= weekStart && date <= now
        }
    }

    private var thisWeekMiles: Double {
        thisWeekActivities.reduce(0) { $0 + ($1.section?.mileage ?? 0) }
    }

    private var thisWeekHours: Double {
        thisWeekActivities.reduce(0) { $0 + $1.duration }
    }

    private var thisWeekGradient: Double {
        let gradients = thisWeekActivities.compactMap { $0.section?.gradient }.filter { $0 > 0 }
        guard !gradients.isEmpty else { return 0 }
        return gradients.reduce(0, +) / Double(gradients.count)
    }

    private var hasPhotos: Bool {
        userActivities.contains { $0.photoData != nil }
    }

    private var uniqueSectionCount: Int {
        Set(userActivities.compactMap { $0.section?.name }).count
    }

    private var totalMilesThisYear: Double {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
        return userActivities
            .filter { ($0.date ?? .distantPast) >= yearStart }
            .reduce(0) { $0 + ($1.section?.mileage ?? 0) }
    }

    private var lastActivityDateString: String {
        guard let date = userActivities.first?.date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private var locationString: String {
        let parts = [profileCity, profileState].filter { !$0.isEmpty }
        return parts.isEmpty ? "No location set" : parts.joined(separator: ", ")
    }

    private var memberSinceYear: String {
        let creationDate = authManager.user?.metadata.creationDate ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: creationDate)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Profile header
                profileHeader

                // Bio
                Text(profileBio.isEmpty ? "No bio yet" : profileBio)
                    .font(.subheadline)
                    .foregroundColor(profileBio.isEmpty ? .secondary : .primary)
                    .padding(.horizontal, 16)

                // Stats row
                statsRow

                // Action buttons
                actionButtons

                // Photo carousel (only if photos exist)
                if hasPhotos {
                    photoCarousel
                }

                Divider()
                    .padding(.vertical, 4)

                // Craft filter
                craftFilter

                // This week
                thisWeekSection

                // Activity chart
                WeeklyMileageGraph(activities: filteredActivities)
                    .padding(.horizontal, 16)

                // Menu rows
                Divider()
                    .padding(.top, 8)
                menuRows

                // Trophy case
                Divider()
                trophyCase

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .overlay(alignment: .top) {
            topBar
        }
        .alert("Coming Soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature is coming soon!")
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView()
        }
        .sheet(isPresented: $showingEditProfile, onDismiss: { loadProfile() }) {
            EditProfileView()
        }
        .fullScreenCover(isPresented: $showingActivities) {
            ProfileActivitiesView()
        }
        .fullScreenCover(isPresented: $showingStatistics) {
            ProfileStatisticsView()
        }
        .fullScreenCover(isPresented: $showingSections) {
            ProfileSectionsView()
        }
        .onAppear { loadProfile() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }
            Spacer()
            HStack(spacing: 20) {
                Button { showingComingSoon = true } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                Button { showingComingSoon = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                Button { showingComingSoon = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 14) {
            // Profile photo placeholder
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("MEMBER SINCE \(memberSinceYear)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                Text(authManager.user?.displayName ?? "River Logger")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Text(locationString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 32) {
            VStack(spacing: 2) {
                Text("Following")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("0")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            VStack(spacing: 2) {
                Text("Followers")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("0")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            VStack(spacing: 2) {
                Text("Activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(userActivities.count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { showingQRCode = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "qrcode")
                        .font(.caption)
                    Text("Share my QR Code")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Theme.primaryBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.primaryBlue, lineWidth: 1.5)
                )
            }

            Button { showingEditProfile = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.caption)
                    Text("Edit")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(Theme.primaryBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.primaryBlue, lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Photo Carousel

    private var photoCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                let activitiesWithPhotos = userActivities.filter { $0.photoData != nil }
                ForEach(activitiesWithPhotos.prefix(4), id: \.id) { activity in
                    if let photoData = activity.photoData as? [Data],
                       let firstPhoto = photoData.first,
                       let uiImage = UIImage(data: firstPhoto) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Button { showingComingSoon = true } label: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("All media")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        )
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Craft Filter

    private var craftFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(craftTypes, id: \.self) { craft in
                    Button {
                        selectedCraftFilter = craft
                    } label: {
                        Text(craft)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedCraftFilter == craft ? Theme.primaryBlue : Color(.systemGray5))
                            .foregroundColor(selectedCraftFilter == craft ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - This Week

    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f mi", thisWeekMiles))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    let hours = Int(thisWeekHours)
                    let minutes = Int((thisWeekHours - Double(hours)) * 60)
                    Text("\(hours)h \(minutes)m")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gradient")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f ft/mi", thisWeekGradient))
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Menu Rows

    private var menuRows: some View {
        VStack(spacing: 0) {
            menuRow(icon: "waveform.path.ecg", title: "Activities", subtitle: lastActivityDateString) { showingActivities = true }
            menuRow(icon: "chart.bar.doc.horizontal", title: "Statistics", subtitle: String(format: "This year: %.1f mi", totalMilesThisYear)) { showingStatistics = true }
            menuRow(icon: "point.bottomleft.forward.to.arrowtriangle.uturn.scurvepath", title: "Sections", subtitle: "\(uniqueSectionCount)") { showingSections = true }
            menuRow(icon: "trophy", title: "Best Efforts", subtitle: "See All") { showingComingSoon = true }
            menuRow(icon: "text.bubble", title: "Posts", subtitle: "—") { showingComingSoon = true }
            menuRow(icon: "figure.rowing", title: "Gear", subtitle: gearSubtitle) { showingComingSoon = true }
        }
    }

    private var gearSubtitle: String {
        // Just show a summary
        "Manage gear"
    }

    private func menuRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button { action() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trophy Case

    private var trophyCase: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trophy Case")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("0")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if userActivities.isEmpty {
                Text("Complete activities to earn trophies!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        if userActivities.count >= 1 {
                            trophyBadge(icon: "star.fill", color: .yellow, label: "1st\nActivity")
                        }
                        if userActivities.count >= 10 {
                            trophyBadge(icon: "flame.fill", color: .orange, label: "10\nActivities")
                        }
                        if userActivities.count >= 50 {
                            trophyBadge(icon: "bolt.fill", color: Theme.primaryBlue, label: "50\nActivities")
                        }
                        if uniqueSectionCount >= 10 {
                            trophyBadge(icon: "map.fill", color: .green, label: "10\nSections")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func trophyBadge(icon: String, color: Color, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Load Profile

    private func loadProfile() {
        Task {
            if let profile = try? await firestoreService.fetchUserProfile() {
                await MainActor.run {
                    profileBio = profile["bio"] as? String ?? ""
                    profileCity = profile["city"] as? String ?? ""
                    profileState = profile["state"] as? String ?? ""
                }
            }
        }
    }
}
