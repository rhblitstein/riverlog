import SwiftUI
import CoreData
import Firebase

@main
struct RiverLogApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthManager()  // ADD THIS
    
    init() {
        // Import river sections on first launch
        RiverSectionImporter.importSections(context: persistenceController.container.viewContext)
        
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(authManager)
                } else {
                    SignInView()
                        .environmentObject(authManager) 
                }
            }
        }
    }
}
