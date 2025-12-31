import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: RiverActivity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)]
    ) private var activities: FetchedResults<RiverActivity>
    
    @State private var selectedTab = 0
    @State private var showingAddActivity = false
    @State private var showingGearManagement = false
    @State private var selectedCraftFilter = "All"
    @State private var showingAccountSettings = false
    @EnvironmentObject var authManager: AuthManager
    
    let craftTypes = ["All", "Raft", "Kayak", "SUP", "Canoe", "Cat", "Duckie", "Packraft"]
    
    var filteredActivities: [RiverActivity] {
        if selectedCraftFilter == "All" {
            return Array(activities)
        }
        return activities.filter { $0.craftType == selectedCraftFilter }
    }
    
    var thisWeekActivities: [RiverActivity] {
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
    
    var thisWeekMiles: Double {
        thisWeekActivities.reduce(0) { $0 + ($1.section?.mileage ?? 0) }
    }
    
    var thisWeekHours: Double {
        thisWeekActivities.reduce(0) { $0 + $1.duration }
    }
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    var streakActivities: Int {
        if currentStreak == 0 { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = Set(activities.compactMap { $0.date?.startOfDay }).sorted(by: >)
        
        guard let mostRecent = sortedDates.first else { return 0 }
        
        var count = 0
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        for date in sortedDates {
            let activityWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            
            if activityWeekStart >= calendar.date(byAdding: .weekOfYear, value: -currentStreak, to: weekStart)! {
                count += activities.filter {
                    guard let actDate = $0.date else { return false }
                    let actWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: actDate))!
                    return actWeekStart == activityWeekStart
                }.count
            }
        }
        
        return count
    }
    
    func calculateStreak() -> Int {
        let calendar = Calendar.current
        let sortedDates = Set(activities.compactMap { $0.date?.startOfDay }).sorted(by: >)
        
        guard let mostRecent = sortedDates.first else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        let daysSinceLastActivity = calendar.dateComponents([.day], from: mostRecent, to: currentDate).day ?? 0
        if daysSinceLastActivity > 7 {
            return 0
        }
        
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate))!
        
        for date in sortedDates {
            let activityWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
            
            if activityWeekStart == weekStart {
                streak += 1
                weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart)!
            } else if activityWeekStart < weekStart {
                break
            }
        }
        
        return streak
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sticky header
                    VStack(spacing: 0) {
                        // "You" banner with buttons
                        HStack {
                            Spacer()
                            Text("You")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Theme.primaryBlue)
                            Spacer()
                        }
                        .frame(height: 60)
                        .background(Color(.systemBackground))
                        .overlay(
                            HStack {
                                Spacer()
                                HStack(spacing: 16) {
                                    Button(action: {
                                        showingAddActivity = true
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.title3)
                                            .foregroundColor(Theme.primaryBlue)
                                    }
                                    Button(action: {
                                        showingAccountSettings = true
                                    }) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.title3)
                                            .foregroundColor(Theme.primaryBlue)
                                    }
                                }
                                .padding(.trailing)
                            }
                        )
                        
                        // Tab selector
                        HStack(spacing: 0) {
                            Button(action: { selectedTab = 0 }) {
                                VStack(spacing: 8) {
                                    Text("Progress")
                                        .font(.headline)
                                        .foregroundColor(selectedTab == 0 ? .primary : .secondary)
                                    Rectangle()
                                        .fill(selectedTab == 0 ? Theme.primaryBlue : Color.clear)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Button(action: { selectedTab = 1 }) {
                                VStack(spacing: 8) {
                                    Text("Activities")
                                        .font(.headline)
                                        .foregroundColor(selectedTab == 1 ? .primary : .secondary)
                                    Rectangle()
                                        .fill(selectedTab == 1 ? Theme.primaryBlue : Color.clear)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
                    }
                    
                    // Content
                    ScrollView {
                        if selectedTab == 0 {
                            progressView
                        } else {
                            activitiesView
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView()
            }
            .sheet(isPresented: $showingGearManagement) {
                GearManagementView()
            }
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
            }
        }
    }
    
    var progressView: some View {
        VStack(spacing: 24) {
            // Craft filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(craftTypes, id: \.self) { craft in
                        Button(action: {
                            selectedCraftFilter = craft
                        }) {
                            Text(craft)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCraftFilter == craft ? Theme.primaryBlue : Color(.systemGray5))
                                .foregroundColor(selectedCraftFilter == craft ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 16)
            
            // This week stats
            VStack(alignment: .leading, spacing: 12) {
                Text("This week")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Distance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f mi", thisWeekMiles))
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        let hours = Int(thisWeekHours)
                        let minutes = Int((thisWeekHours - Double(hours)) * 60)
                        Text(String(format: "%dh %dm", hours, minutes))
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal)
                
                // Graph
                WeeklyMileageGraph(activities: filteredActivities)
                    .padding(.horizontal)
            }
            
            // See more progress button
            NavigationLink(destination: DetailedProgressView()) {
                Text("See more of your progress")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryBlue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            // Calendar view
            CalendarView(activities: Array(activities), currentStreak: currentStreak, streakActivities: streakActivities)
                .padding(.top, 24)
            
            Spacer()
        }
    }
    
    var activitiesView: some View {
        VStack(spacing: 12) {
            ForEach(activities, id: \.id) { activity in
                NavigationLink(destination: ActivityDetailView(activity: activity)) {
                    ActivityCardView(activity: activity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
