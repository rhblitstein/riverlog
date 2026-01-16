import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let authService = AuthService.shared
    
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.login(email: email, password: password)
        } catch let error as APIError {
            switch error {
            case .serverError(let message):
                errorMessage = message
            case .unauthorized:
                errorMessage = "Invalid email or password"
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            default:
                errorMessage = "Login failed. Please try again."
            }
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func register() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.register(
                email: email,
                password: password,
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
        } catch let error as APIError {
            switch error {
            case .serverError(let message):
                errorMessage = message
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            default:
                errorMessage = "Registration failed. Please try again."
            }
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
}
