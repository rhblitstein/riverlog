import SwiftUI
import CoreData

@main
struct RiverLogApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Import river sections on first launch
        RiverSectionImporter.importSections(context: persistenceController.container.viewContext)
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
