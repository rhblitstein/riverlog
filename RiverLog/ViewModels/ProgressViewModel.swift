import Foundation
import CoreData
import SwiftUI
import Combine

class ProgressViewModel: ObservableObject {
    @Published var filters = ProgressFilters()
    
    // Filter activities based on current filters
    func filterActivities(_ activities: [RiverActivity]) -> [RiverActivity] {
        var filtered = activities
        
        // Time period filter
        filtered = filtered.filter { activity in
            guard let date = activity.date else { return false }
            
            switch filters.timePeriod {
            case .week:
                return isDateInCurrentWeek(date)
            case .month:
                return isDateInCurrentMonth(date)
            case .threeMonths:
                return isDateInThreeMonths(date)
            case .sixMonths:
                return isDateInSixMonths(date)
            case .year:
                return isDateInCurrentYear(date)
            case .lifetime:
                return true
            }
        }
        
        // Trip type filter
        filtered = filtered.filter { activity in
            let tripType = activity.tripType ?? "Private"
            
            switch filters.tripType {
            case .all:
                return true
            case .privateWithTraining:
                return tripType == "Private" || tripType == "Training"
            case .privateNoTraining:
                return tripType == "Private"
            case .commercial:
                return tripType == "Commercial"
            case .training:
                return tripType == "Training"
            }
        }
        
        // Class filter
        filtered = filtered.filter { activity in
            guard let section = activity.section,
                  let classRating = section.classRating else { return false }
            
            switch filters.classFilter {
            case .all:
                return true
            case .classIIIPlus:
                return isClassIIIOrHigher(classRating)
            case .classIVPlus:
                return isClassIVOrHigher(classRating)
            case .classVPlus:
                return isClassVOrHigher(classRating)
            }
        }
        
        return filtered
    }
    
    // MARK: - Stats Calculations
    
    func totalMiles(from activities: [RiverActivity]) -> Double {
        activities.reduce(0) { $0 + ($1.section?.mileage ?? 0) }
    }
    
    func totalTrips(from activities: [RiverActivity]) -> Int {
        activities.count
    }
    
    func totalHours(from activities: [RiverActivity]) -> Double {
        activities.reduce(0) { $0 + $1.duration }
    }
    
    func milesByClass(from activities: [RiverActivity]) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        
        for activity in activities {
            guard let section = activity.section,
                  let classRating = section.classRating else { continue }
            
            let simplified = simplifyClassRating(classRating)
            breakdown[simplified, default: 0] += section.mileage
        }
        
        return breakdown
    }
    
    // MARK: - Helper Functions
    
    private func isDateInCurrentWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return false
        }
        return date >= weekStart && date <= now
    }
    
    private func isDateInCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    private func isDateInCurrentYear(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .year)
    }
    
    private func isDateInThreeMonths(_ date: Date) -> Bool {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        return date >= threeMonthsAgo && date <= Date()
    }

    private func isDateInSixMonths(_ date: Date) -> Bool {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        return date >= sixMonthsAgo && date <= Date()
    }
    
    private func isClassIIIOrHigher(_ rating: String) -> Bool {
        let normalized = rating.uppercased()
        return normalized.contains("III") || normalized.contains("IV") || normalized.contains("V")
    }
    
    private func isClassIVOrHigher(_ rating: String) -> Bool {
        let normalized = rating.uppercased()
        return normalized.contains("IV") || normalized.contains("V")
    }
    
    private func isClassVOrHigher(_ rating: String) -> Bool {
        let normalized = rating.uppercased()
        return normalized.contains("V") && !normalized.contains("IV")
    }
    
    private func simplifyClassRating(_ rating: String) -> String {
        let normalized = rating.uppercased()
        
        if normalized.contains("V") && !normalized.contains("IV") {
            return "V"
        } else if normalized.contains("IV") {
            return "IV"
        } else if normalized.contains("III") {
            return "III"
        } else if normalized.contains("II") {
            return "II"
        } else if normalized.contains("I") {
            return "I"
        }
        
        return "Other"
    }
}
