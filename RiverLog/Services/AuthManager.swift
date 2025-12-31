import Foundation
import FirebaseAuth
import Combine
import CoreData

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        // Listen for auth state changes
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        
        // Reload user
        try await result.user.reload()
        await MainActor.run {
            self.user = Auth.auth().currentUser
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.user = result.user
        }
        
        // Sync activities from Firestore
        let context = PersistenceController.shared.container.viewContext
        let firestoreService = FirestoreService()
        try await firestoreService.fetchActivitiesFromFirestore(context: context)
        try await firestoreService.fetchGearFromFirestore(context: context)
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
        isAuthenticated = false
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
