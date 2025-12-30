import SwiftUI

struct CalendarView: View {
    let activities: [RiverActivity]
    let currentStreak: Int
    let streakActivities: Int
    
    @State private var currentMonth = Date()
    
    var calendar: Calendar {
        Calendar.current
    }
    
    func craftIcon(for craftType: String) -> String {
        switch craftType {
        case "Raft": return "🚣"
        case "Kayak": return "🛶"
        case "SUP": return "🏄"
        case "Canoe": return "🛶"
        case "Cat": return "⛵"
        case "Duckie": return "🦆"
        case "Packraft": return "🎒"
        default: return "🌊"
        }
    }
    
    func activitiesForDate(_ date: Date) -> [RiverActivity] {
        activities.filter { activity in
            guard let activityDate = activity.date else { return false }
            return calendar.isDate(activityDate, inSameDayAs: date)
        }
    }
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var dates: [Date] = []
        var date = monthFirstWeek.start
        
        while date < monthInterval.end {
            dates.append(date)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = nextDate
        }
        
        // Pad to fill the grid
        while dates.count % 7 != 0 {
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: dates.last!) else { break }
            dates.append(nextDate)
        }
        
        return dates
    }
    
    var numberOfWeeks: Int {
        daysInMonth.count / 7
    }
    
    let rowHeight: CGFloat = 40
    let cellSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with month/year
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Streak info
            HStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(currentStreak) Weeks")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                if currentStreak > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak Activities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(streakActivities)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Calendar grid with streak indicator
            HStack(alignment: .top, spacing: 0) {
                // Calendar
                VStack(spacing: 4) {
                    // Day headers
                    HStack(spacing: 0) {
                        ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(width: cellSize)
                        }
                    }
                    .frame(height: 20)
                    
                    // Calendar weeks
                    ForEach(0..<numberOfWeeks, id: \.self) { weekIndex in
                        HStack(spacing: 2) {
                            ForEach(0..<7) { dayIndex in
                                let dateIndex = weekIndex * 7 + dayIndex
                                if dateIndex < daysInMonth.count {
                                    let date = daysInMonth[dateIndex]
                                    let dayActivities = activitiesForDate(date)
                                    let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
                                    
                                    ZStack {
                                        if !dayActivities.isEmpty {
                                            Text(craftIcon(for: dayActivities.first?.craftType ?? ""))
                                                .font(.caption)
                                        } else if isCurrentMonth {
                                            Text("\(calendar.component(.day, from: date))")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .frame(width: cellSize, height: cellSize)
                                    .background(
                                        Circle()
                                            .stroke(!dayActivities.isEmpty ? Theme.primaryBlue : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.leading)
                
                // Streak indicator aligned with weeks
                VStack(spacing: 4) {
                    // Header spacer
                    Spacer()
                        .frame(height: 20)
                    
                    ForEach(0..<numberOfWeeks, id: \.self) { week in
                        Group {
                            if week < currentStreak && week < numberOfWeeks - 1 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundColor(Theme.primaryBlue)
                            } else if week == numberOfWeeks - 1 {
                                // Last week shows the streak inside drop
                                ZStack {
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Theme.primaryBlue)
                                    
                                    Text("\(currentStreak)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .offset(y: 2) // Adjust vertical position to center in drop
                                }
                            } else {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .frame(height: rowHeight)
                    }
                }
                .frame(width: 50)
                .padding(.trailing)
            }
        }
    }
}
