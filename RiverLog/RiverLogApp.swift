//
//  RiverLogApp.swift
//  RiverLog
//
//  Created by Rebecca Blitstein on 12/29/25.
//

import SwiftUI
import CoreData

@main
struct RiverLogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
