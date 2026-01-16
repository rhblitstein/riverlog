import SwiftUI
import Combine

@MainActor
class TripListViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let authService = AuthService.shared
    
    var totalMiles: Double {
        trips.reduce(0) { $0 + ($1.mileage ?? 0) }
    }
    
    var totalTrips: Int {
        trips.count
    }
    
    var uniqueRivers: Int {
        Set(trips.map { $0.riverName }).count
    }
    
    func loadTrips() async {
        guard let token = authService.token else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            trips = try await apiService.getTrips(token: token)
            // Sort by date descending (newest first)
            trips.sort { $0.tripDate > $1.tripDate }
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                authService.logout()
            case .serverError(let message):
                errorMessage = message
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            default:
                errorMessage = "Failed to load trips"
            }
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func deleteTrip(_ trip: Trip) async {
        guard let token = authService.token else { return }
        
        do {
            try await apiService.deleteTrip(id: trip.id, token: token)
            trips.removeAll { $0.id == trip.id }
        } catch let error as APIError {
            switch error {
            case .unauthorized:
                authService.logout()
            case .serverError(let message):
                errorMessage = message
            default:
                errorMessage = "Failed to delete trip"
            }
        } catch {
            errorMessage = "An unexpected error occurred"
        }
    }
}
