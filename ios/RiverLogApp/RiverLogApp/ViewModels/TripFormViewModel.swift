import SwiftUI
import Combine

@MainActor
class TripFormViewModel: ObservableObject {
    @Published var selectedSection: Section?
    @Published var sections: [Section] = []
    @Published var searchText = ""
    @Published var isLoadingSections = false
    
    @Published var tripDate = Date()
    @Published var difficulty = ""
    @Published var flow = ""
    @Published var flowUnit = "cfs"
    @Published var craftType = ""
    @Published var durationMinutes = ""
    @Published var mileage = ""
    @Published var notes = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let authService = AuthService.shared
    
    var existingTrip: Trip?
    var isEditing: Bool { existingTrip != nil }
    
    func loadSections() async {
        guard let token = authService.token else { return }
        
        isLoadingSections = true
        
        do {
            sections = try await apiService.getSections(token: token, search: searchText.isEmpty ? nil : searchText)
        } catch {
            errorMessage = "Failed to load sections"
        }
        
        isLoadingSections = false
    }
    
    func loadTrip(_ trip: Trip) async {
        guard let token = authService.token else { return }
        
        existingTrip = trip
        
        // Fetch the full section data
        do {
            let allSections = try await apiService.getSections(token: token)
            selectedSection = allSections.first { $0.id == trip.sectionId }
        } catch {
            errorMessage = "Failed to load section data"
        }
        
        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dateString = trip.tripDate.split(separator: "T").first,
           let date = formatter.date(from: String(dateString)) {
            tripDate = date
        }
        
        difficulty = trip.difficulty ?? ""
        flow = trip.flow.map { String($0) } ?? ""
        flowUnit = trip.flowUnit ?? "cfs"
        craftType = trip.craftType ?? ""
        durationMinutes = trip.durationMinutes.map { String($0) } ?? ""
        mileage = trip.mileage.map { String($0) } ?? ""
        notes = trip.notes ?? ""
    }
    
    func saveTrip() async -> Bool {
        guard let section = selectedSection else {
            errorMessage = "Please select a section"
            return false
        }
        
        guard let token = authService.token else {
            errorMessage = "Not authenticated"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        // Format date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: tripDate)
        
        let request = CreateTripRequest(
            sectionId: section.id,
            tripDate: dateString,
            difficulty: difficulty.isEmpty ? nil : difficulty,
            flow: Int(flow),
            flowUnit: flowUnit,
            craftType: craftType.isEmpty ? nil : craftType,
            durationMinutes: Int(durationMinutes),
            mileage: Double(mileage),
            notes: notes.isEmpty ? nil : notes
        )
        
        do {
            if let trip = existingTrip {
                _ = try await apiService.updateTrip(id: trip.id, trip: request, token: token)
            } else {
                _ = try await apiService.createTrip(trip: request, token: token)
            }
            isLoading = false
            return true
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                authService.logout()
                errorMessage = "Session expired. Please login again."
            case .serverError(let message):
                errorMessage = message
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            default:
                errorMessage = "Failed to save trip"
            }
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
        return false
    }
}
