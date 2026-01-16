import Foundation
import Combine

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var token: String?
    
    private let apiService = APIService.shared
    private let keychainService = KeychainService.shared
    
    private init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let savedToken = keychainService.getToken() {
            token = savedToken
            isAuthenticated = true
            
            // Fetch current user
            Task {
                do {
                    currentUser = try await apiService.getCurrentUser(token: savedToken)
                } catch {
                    // Token might be expired, log out
                    logout()
                }
            }
        }
    }
    
    func login(email: String, password: String) async throws {
        let authToken = try await apiService.login(email: email, password: password)
        
        // Save token to keychain
        _ = keychainService.saveToken(authToken.token)
        
        token = authToken.token
        currentUser = authToken.user
        isAuthenticated = true
    }
    
    func register(email: String, password: String, firstName: String?, lastName: String?) async throws {
        _ = try await apiService.register(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        
        // Auto-login after registration
        try await login(email: email, password: password)
    }
    
    func logout() {
        _ = keychainService.deleteToken()
        token = nil
        currentUser = nil
        isAuthenticated = false
    }
}
