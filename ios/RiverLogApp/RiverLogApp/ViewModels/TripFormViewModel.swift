import SwiftUI
import Combine

@MainActor
class TripFormViewModel: ObservableObject {
    @Published var riverName = ""
    @Published var sectionName = ""
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
    
    func loadTrip(_ trip: Trip) {
        existingTrip = trip
        riverName = trip.riverName
        sectionName = trip.sectionName
        
        // Parse date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: trip.tripDate) {
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
        guard !riverName.isEmpty, !sectionName.isEmpty else {
            errorMessage = "River name and section are required"
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
            riverName: riverName,
            sectionName: sectionName,
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
