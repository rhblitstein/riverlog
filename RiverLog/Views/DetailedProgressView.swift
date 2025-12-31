import SwiftUI
import CoreData
import FirebaseAuth

struct DetailedProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthManager
    
    @StateObject private var progressViewModel = ProgressViewModel()
    
    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var allActivities: FetchedResults<RiverActivity>
    
    // Filter activities by current user
    private var userActivities: [RiverActivity] {
        allActivities.filter { $0.userId == authManager.user?.uid }
    }
    
    // Apply progress filters
    private var filteredActivities: [RiverActivity] {
        progressViewModel.filterActivities(userActivities)
    }
    
    private var totalMiles: Double {
        progressViewModel.totalMiles(from: filteredActivities)
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let calendar = Calendar.current
        let now = Date()
        
        switch progressViewModel.filters.timePeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -6, to: now)!
            return "\(formatter.string(from: start)) - \(formatter.string(from: now))"
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: startOfMonth)!)!
            return "\(formatter.string(from: startOfMonth)) - \(formatter.string(from: endOfMonth))"
        case .threeMonths:
            let start = calendar.date(byAdding: .month, value: -2, to: now)!
            let startOfPeriod = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
            return "\(formatter.string(from: startOfPeriod)) - \(formatter.string(from: now))"
        case .sixMonths:
            let start = calendar.date(byAdding: .month, value: -5, to: now)!
            let startOfPeriod = calendar.date(from: calendar.dateComponents([.year, .month], from: start))!
            return "\(formatter.string(from: startOfPeriod)) - \(formatter.string(from: now))"
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return "\(formatter.string(from: start)) - \(formatter.string(from: now))"
        case .lifetime:
            return "All time"
        }
    }
    
    private var tripTypeLabel: String {
        switch progressViewModel.filters.tripType {
        case .all: return "All trip types"
        case .privateWithTraining: return "Private (incl. Training)"
        case .privateNoTraining: return "Private (excl. Training)"
        case .commercial: return "Commercial"
        case .training: return "Training Only"
        }
    }
    
    private var classFilterLabel: String {
        progressViewModel.filters.classFilter.rawValue
    }
    
    var body: some View {
        ZStack {
            Theme.pageBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Smaller pill-shaped dropdowns
                    HStack(spacing: 12) {
                        // Trip Type Dropdown
                        Menu {
                            ForEach(ProgressFilters.TripTypeFilter.allCases, id: \.self) { type in
                                Button(action: {
                                    progressViewModel.filters.tripType = type
                                }) {
                                    HStack {
                                        Text(labelFor(tripType: type))
                                        if progressViewModel.filters.tripType == type {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(tripTypeLabel)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        
                        // Class Dropdown
                        Menu {
                            ForEach(ProgressFilters.ClassFilter.allCases, id: \.self) { classFilter in
                                Button(action: {
                                    progressViewModel.filters.classFilter = classFilter
                                }) {
                                    HStack {
                                        Text(classFilter.rawValue)
                                        if progressViewModel.filters.classFilter == classFilter {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(classFilterLabel)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Big stat display
                    VStack(spacing: 4) {
                        Text("Total Distance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f mi", totalMiles))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Theme.primaryBlue)
                        
                        Text(dateRangeText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Graph with time periods
                    VStack(spacing: 0) {
                        // Graph
                        MileageGraph(
                            activities: filteredActivities,
                            timePeriod: progressViewModel.filters.timePeriod
                        )
                        .padding(.horizontal, 16)
                        
                        // Time period selector
                        HStack(spacing: 0) {
                            TimePeriodButton(
                                title: "7D",
                                isSelected: progressViewModel.filters.timePeriod == .week
                            ) {
                                progressViewModel.filters.timePeriod = .week
                            }
                            
                            TimePeriodButton(
                                title: "1M",
                                isSelected: progressViewModel.filters.timePeriod == .month
                            ) {
                                progressViewModel.filters.timePeriod = .month
                            }
                            
                            TimePeriodButton(
                                title: "3M",
                                isSelected: progressViewModel.filters.timePeriod == .threeMonths
                            ) {
                                progressViewModel.filters.timePeriod = .threeMonths
                            }
                            
                            TimePeriodButton(
                                title: "6M",
                                isSelected: progressViewModel.filters.timePeriod == .sixMonths
                            ) {
                                progressViewModel.filters.timePeriod = .sixMonths
                            }
                            
                            TimePeriodButton(
                                title: "1Y",
                                isSelected: progressViewModel.filters.timePeriod == .year
                            ) {
                                progressViewModel.filters.timePeriod = .year
                            }
                            
                            TimePeriodButton(
                                title: "All time",
                                isSelected: progressViewModel.filters.timePeriod == .lifetime
                            ) {
                                progressViewModel.filters.timePeriod = .lifetime
                            }
                        }
                        .background(Color(.systemGray6))
                    }
                    .padding(.horizontal, 16)
                    
                    // Stats cards row
                    HStack(spacing: 12) {
                        ProgressStatCard(
                            title: "Miles",
                            value: String(format: "%.1f", progressViewModel.totalMiles(from: filteredActivities)),
                            icon: "arrow.right"
                        )
                        
                        ProgressStatCard(
                            title: "Trips",
                            value: "\(progressViewModel.totalTrips(from: filteredActivities))",
                            icon: "flag.fill"
                        )
                        
                        ProgressStatCard(
                            title: "Hours",
                            value: String(format: "%.1f", progressViewModel.totalHours(from: filteredActivities)),
                            icon: "clock.fill"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Miles by Class
                    milesByClassSection

                    // Streaks
                    streaksSection

                    // Section Stats
                    sectionStatsSection

                    // River Stats
                    riverStatsSection

                    // Personal Records
                    personalRecordsSection

                    // Certifications
                    certificationsSection
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Progress")
                    .font(.headline)
                    .foregroundColor(Theme.primaryBlue)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func labelFor(tripType: ProgressFilters.TripTypeFilter) -> String {
        switch tripType {
        case .all: return "All trip types"
        case .privateWithTraining: return "Private (incl. Training)"
        case .privateNoTraining: return "Private (excl. Training)"
        case .commercial: return "Commercial"
        case .training: return "Training Only"
        }
    }
    
    // MARK: - Sections
    
    private var milesByClassSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Miles by Class")
                .font(.headline)
            
            let breakdown = progressViewModel.milesByClass(from: filteredActivities)
            
            if breakdown.isEmpty {
                Text("No data for selected filters")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(["I", "II", "III", "IV", "V"], id: \.self) { classRating in
                        if let miles = breakdown[classRating], miles > 0 {
                            HStack {
                                Text("Class \(classRating)")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f mi", miles))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Theme.primaryBlue)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Streaks")
                .font(.headline)

            let swimStreaks = progressViewModel.swimStreaks(from: filteredActivities)
            let carnageStreaks = progressViewModel.carnageStreaks(from: filteredActivities)
            let boatingStreaks = progressViewModel.boatingStreaks(from: filteredActivities)

            VStack(spacing: 12) {
                // No-Swim Streaks
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No-Swim Streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(swimStreaks.current)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.primaryBlue)
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(swimStreaks.longest)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Longest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "figure.pool.swim")
                        .font(.title2)
                        .foregroundColor(Theme.primaryBlue)
                }

                Divider()

                // No-Carnage Streaks
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No-Carnage Streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(carnageStreaks.current)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.primaryBlue)
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(carnageStreaks.longest)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Longest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.orange)
                }

                Divider()

                // Boating Streaks (weeks)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weekly Boating Streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            VStack {
                                Text("\(boatingStreaks.current)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.primaryBlue)
                                Text("Current")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text("\(boatingStreaks.longest)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Longest")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var sectionStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Section Stats")
                .font(.headline)

            if let mostRun = progressViewModel.mostRunSection(from: filteredActivities) {
                HStack {
                    Text("Most Run Section:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(mostRun)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.primaryBlue)
                }
                .padding(.bottom, 8)
            }

            let stats = progressViewModel.sectionStats(from: filteredActivities)

            if stats.isEmpty {
                Text("No section data for selected filters")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Table header
                HStack {
                    Text("Section")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Trips")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 50)
                    Text("Miles")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 50)
                    Text("Flow Range")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 80)
                }
                .foregroundColor(.secondary)

                ForEach(stats.prefix(10)) { stat in
                    VStack(spacing: 4) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stat.sectionName)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text(stat.riverName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Text("\(stat.totalTrips)")
                                .font(.caption)
                                .frame(width: 50)

                            Text(String(format: "%.1f", stat.totalMiles))
                                .font(.caption)
                                .frame(width: 50)

                            if let low = stat.lowestFlow, let high = stat.highestFlow {
                                Text("\(Int(low))-\(Int(high))")
                                    .font(.caption)
                                    .frame(width: 80)
                            } else {
                                Text("-")
                                    .font(.caption)
                                    .frame(width: 80)
                            }
                        }
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var riverStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("River Stats")
                .font(.headline)

            let topRivers = progressViewModel.topRivers(from: filteredActivities, count: 5)

            if topRivers.isEmpty {
                Text("No river data for selected filters")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text("Top 5 Rivers by Trips")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(topRivers) { river in
                    VStack(spacing: 8) {
                        HStack {
                            Text(river.riverName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(river.totalTrips) trips")
                                .font(.caption)
                                .foregroundColor(Theme.primaryBlue)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total: \(String(format: "%.1f", river.totalMiles)) mi")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Commercial: \(river.commercialTrips)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("Private: \(river.privateTrips)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Records")
                .font(.headline)

            let records = progressViewModel.personalRecords(from: filteredActivities)

            VStack(spacing: 12) {
                // Hardest Class
                if let hardest = records.hardestClass {
                    HStack {
                        Label("Hardest Class", systemImage: "star.fill")
                            .font(.subheadline)
                        Spacer()
                        Text("Class \(formatClassRating(hardest))")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.primaryBlue)
                    }
                }

                Divider()

                // Average Classes
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avg Class (Private)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(records.averageClassPrivate ?? "-")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Avg Class (Commercial)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(records.averageClassCommercial ?? "-")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Divider()

                // Longest Trip
                if let longest = records.longestTrip {
                    HStack {
                        Label("Longest Trip", systemImage: "clock.fill")
                            .font(.subheadline)
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(String(format: "%.1f hrs", longest.duration))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.primaryBlue)
                            Text(longest.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Total Elevation Loss
                HStack {
                    Label("Total Elevation Loss", systemImage: "arrow.down.forward")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "%.0f ft", records.totalElevationLoss))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.primaryBlue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private func formatClassRating(_ rating: String) -> String {
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

    private var certificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Colorado Guide Certifications")
                .font(.headline)
            
            // TL Certification
            CertificationCard(
                title: "Trip Leader (TL)",
                totalMiles: progressViewModel.totalMiles(from: userActivities),
                commercialMiles: progressViewModel.totalMiles(from: userActivities.filter { $0.tripType == "Commercial" }),
                requiredTotal: 500,
                requiredCommercial: 250
            )
            
            // Class IV Guide
            let classIIIPlusActivities = userActivities.filter { activity in
                guard let section = activity.section, let classRating = section.classRating else { return false }
                return classRating.uppercased().contains("III") || classRating.uppercased().contains("IV") || classRating.uppercased().contains("V")
            }
            
            CertificationCard(
                title: "Class IV Guide",
                totalMiles: progressViewModel.totalMiles(from: classIIIPlusActivities),
                commercialMiles: progressViewModel.totalMiles(from: classIIIPlusActivities.filter { $0.tripType == "Commercial" }),
                requiredTotal: 1000,
                requiredCommercial: 500
            )
            
            // Trainer
            CertificationCard(
                title: "Trainer",
                totalMiles: progressViewModel.totalMiles(from: userActivities),
                commercialMiles: progressViewModel.totalMiles(from: userActivities.filter { $0.tripType == "Commercial" }),
                requiredTotal: 1500,
                requiredCommercial: 750
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Supporting Views

struct TimePeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color(.systemGray5) : Color.clear)
        }
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.primaryBlue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CertificationCard: View {
    let title: String
    let totalMiles: Double
    let commercialMiles: Double
    let requiredTotal: Double
    let requiredCommercial: Double
    
    private var isComplete: Bool {
        totalMiles >= requiredTotal && commercialMiles >= requiredCommercial
    }
    
    private var progress: Double {
        min(totalMiles / requiredTotal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(isComplete ? Color.green : Theme.primaryBlue)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Stats
            VStack(spacing: 4) {
                HStack {
                    Text("Total:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(totalMiles))/\(Int(requiredTotal)) mi")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Commercial:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(commercialMiles))/\(Int(requiredCommercial)) mi")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
