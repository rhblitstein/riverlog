import Foundation

struct ProgressFilters {
    var timePeriod: TimePeriod = .threeMonths
    var tripType: TripTypeFilter = .all
    var classFilter: ClassFilter = .all
    
    enum TimePeriod: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case year = "This Year"
        case lifetime = "Lifetime"
    }
    
    enum TripTypeFilter: String, CaseIterable {
        case all = "All"
        case privateWithTraining = "Private (incl. Training)"
        case privateNoTraining = "Private (excl. Training)"
        case commercial = "Commercial"
        case training = "Training Only"
    }
    
    enum ClassFilter: String, CaseIterable {
        case all = "All Classes"
        case classIIIPlus = "Class III+"
        case classIVPlus = "Class IV+"
        case classVPlus = "Class V+"
    }
}
