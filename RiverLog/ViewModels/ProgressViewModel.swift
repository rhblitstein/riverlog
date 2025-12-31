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

    // MARK: - Streak Calculations

    /// Calculates no-swim streaks from filtered activities
    func swimStreaks(from activities: [RiverActivity]) -> (current: Int, longest: Int) {
        let sorted = activities.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }

        var longestStreak = 0
        var tempStreak = 0

        for activity in sorted {
            if !activity.didSwim {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }

        // Current streak is the streak ending at the most recent trip
        let currentStreak = tempStreak

        return (current: currentStreak, longest: longestStreak)
    }

    /// Calculates no-carnage streaks from filtered activities
    func carnageStreaks(from activities: [RiverActivity]) -> (current: Int, longest: Int) {
        let sorted = activities.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }

        var longestStreak = 0
        var tempStreak = 0

        for activity in sorted {
            if !activity.hadCarnage {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 0
            }
        }

        let currentStreak = tempStreak

        return (current: currentStreak, longest: longestStreak)
    }

    /// Calculates boating streaks (consecutive weeks with at least one trip)
    func boatingStreaks(from activities: [RiverActivity]) -> (current: Int, longest: Int) {
        guard !activities.isEmpty else { return (0, 0) }

        let calendar = Calendar.current

        // Get unique weeks that have activities (year * 100 + weekOfYear for unique identifier)
        var weeksWithTrips: Set<Int> = []
        for activity in activities {
            guard let date = activity.date else { continue }
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let year = calendar.component(.year, from: date)
            let combinedWeek = year * 100 + weekOfYear
            weeksWithTrips.insert(combinedWeek)
        }

        let sortedWeeks = weeksWithTrips.sorted()
        guard !sortedWeeks.isEmpty else { return (0, 0) }

        var longestStreak = 1
        var tempStreak = 1

        for i in 1..<sortedWeeks.count {
            let prevWeek = sortedWeeks[i - 1]
            let currWeek = sortedWeeks[i]

            // Check if consecutive week (handles year boundary)
            let prevYear = prevWeek / 100
            let prevWeekNum = prevWeek % 100
            let currYear = currWeek / 100
            let currWeekNum = currWeek % 100

            let isConsecutive = (currYear == prevYear && currWeekNum == prevWeekNum + 1) ||
                               (currYear == prevYear + 1 && prevWeekNum >= 52 && currWeekNum == 1)

            if isConsecutive {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }

        // Check if current week is part of streak
        let currentWeek = calendar.component(.weekOfYear, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        let currentCombined = currentYear * 100 + currentWeek

        var currentStreak = 0
        if let lastWeek = sortedWeeks.last {
            let lastYear = lastWeek / 100
            let lastWeekNum = lastWeek % 100

            if lastWeek == currentCombined ||
               (currentYear == lastYear && currentWeek == lastWeekNum + 1) ||
               (currentYear == lastYear + 1 && lastWeekNum >= 52 && currentWeek == 1) {
                currentStreak = tempStreak
            }
        }

        return (current: currentStreak, longest: longestStreak)
    }

    // MARK: - Section Stats

    struct SectionStat: Identifiable {
        let id = UUID()
        let sectionName: String
        let riverName: String
        let totalTrips: Int
        let commercialTrips: Int
        let privateTrips: Int
        let totalMiles: Double
        let commercialMiles: Double
        let privateMiles: Double
        let highestFlow: Double?
        let lowestFlow: Double?
        let flowUnit: String?
    }

    func mostRunSection(from activities: [RiverActivity]) -> String? {
        let sectionCounts = Dictionary(grouping: activities) { $0.section?.name ?? "Unknown" }
        return sectionCounts.max(by: { $0.value.count < $1.value.count })?.key
    }

    func sectionStats(from activities: [RiverActivity]) -> [SectionStat] {
        let grouped = Dictionary(grouping: activities) { $0.section?.id ?? UUID() }

        return grouped.compactMap { (_, sectionActivities) -> SectionStat? in
            guard let firstActivity = sectionActivities.first,
                  let section = firstActivity.section else { return nil }

            let commercial = sectionActivities.filter { $0.tripType == "Commercial" }
            let privateTrips = sectionActivities.filter { $0.tripType == "Private" || $0.tripType == "Training" }

            let flows = sectionActivities.compactMap { $0.flowValue > 0 ? $0.flowValue : nil }

            return SectionStat(
                sectionName: section.name ?? "Unknown",
                riverName: section.riverName ?? "Unknown",
                totalTrips: sectionActivities.count,
                commercialTrips: commercial.count,
                privateTrips: privateTrips.count,
                totalMiles: Double(sectionActivities.count) * section.mileage,
                commercialMiles: Double(commercial.count) * section.mileage,
                privateMiles: Double(privateTrips.count) * section.mileage,
                highestFlow: flows.max(),
                lowestFlow: flows.min(),
                flowUnit: sectionActivities.first?.flowUnit
            )
        }.sorted { $0.totalTrips > $1.totalTrips }
    }

    // MARK: - River Stats

    struct RiverStat: Identifiable {
        let id = UUID()
        let riverName: String
        let totalTrips: Int
        let commercialTrips: Int
        let privateTrips: Int
        let totalMiles: Double
        let commercialMiles: Double
        let privateMiles: Double
    }

    func riverStats(from activities: [RiverActivity]) -> [RiverStat] {
        let grouped = Dictionary(grouping: activities) { $0.section?.riverName ?? "Unknown" }

        return grouped.map { (riverName, riverActivities) -> RiverStat in
            let commercial = riverActivities.filter { $0.tripType == "Commercial" }
            let privateTrips = riverActivities.filter { $0.tripType == "Private" || $0.tripType == "Training" }

            let totalMiles = riverActivities.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
            let commercialMiles = commercial.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }
            let privateMiles = privateTrips.reduce(0.0) { $0 + ($1.section?.mileage ?? 0) }

            return RiverStat(
                riverName: riverName,
                totalTrips: riverActivities.count,
                commercialTrips: commercial.count,
                privateTrips: privateTrips.count,
                totalMiles: totalMiles,
                commercialMiles: commercialMiles,
                privateMiles: privateMiles
            )
        }.sorted { $0.totalTrips > $1.totalTrips }
    }

    func topRivers(from activities: [RiverActivity], count: Int = 5) -> [RiverStat] {
        Array(riverStats(from: activities).prefix(count))
    }

    // MARK: - Personal Records

    struct PersonalRecords {
        let hardestClass: String?
        let averageClassPrivate: String?
        let averageClassCommercial: String?
        let longestTrip: (duration: Double, title: String)?
        let totalElevationLoss: Double
    }

    func personalRecords(from activities: [RiverActivity]) -> PersonalRecords {
        // Hardest class completed
        let classOrder = ["I", "II", "III", "IV", "V"]
        var hardestIndex = -1
        var hardestRating: String? = nil

        for activity in activities {
            guard let classRating = activity.section?.classRating else { continue }
            let simplified = simplifyClassRating(classRating)
            if let index = classOrder.firstIndex(of: simplified), index > hardestIndex {
                hardestIndex = index
                hardestRating = classRating
            }
        }

        // Average class for private trips
        let privateActivities = activities.filter { $0.tripType == "Private" || $0.tripType == "Training" }
        let avgPrivate = averageClass(from: privateActivities)

        // Average class for commercial trips
        let commercialActivities = activities.filter { $0.tripType == "Commercial" }
        let avgCommercial = averageClass(from: commercialActivities)

        // Longest single trip by duration
        let longestActivity = activities.max(by: { $0.duration < $1.duration })
        let longestTrip: (Double, String)? = longestActivity.map { ($0.duration, $0.title ?? "Unknown") }

        // Total elevation loss (gradient in fpm * mileage in miles)
        let totalElevation = activities.reduce(0.0) { total, activity in
            guard let section = activity.section else { return total }
            let elevationLoss = section.gradient * section.mileage
            return total + elevationLoss
        }

        return PersonalRecords(
            hardestClass: hardestRating,
            averageClassPrivate: avgPrivate,
            averageClassCommercial: avgCommercial,
            longestTrip: longestTrip,
            totalElevationLoss: totalElevation
        )
    }

    private func averageClass(from activities: [RiverActivity]) -> String? {
        guard !activities.isEmpty else { return nil }

        let classValues: [String: Double] = ["I": 1, "II": 2, "III": 3, "IV": 4, "V": 5]
        var total = 0.0
        var count = 0

        for activity in activities {
            guard let classRating = activity.section?.classRating else { continue }
            let simplified = simplifyClassRating(classRating)
            if let value = classValues[simplified] {
                total += value
                count += 1
            }
        }

        guard count > 0 else { return nil }

        let average = total / Double(count)
        let rounded = Int(average.rounded())
        let classNames = ["I", "II", "III", "IV", "V"]

        if rounded >= 1 && rounded <= 5 {
            return "Class \(classNames[rounded - 1])"
        }
        return nil
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
