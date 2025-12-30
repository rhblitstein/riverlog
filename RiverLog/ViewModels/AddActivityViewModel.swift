import Foundation
import CoreData
import Combine
import UIKit

class AddActivityViewModel: ObservableObject {
    // Form fields
    @Published var title = ""
    @Published var activityDescription = ""
    @Published var sectionName = ""
    @Published var craftType = "Raft"
    @Published var date = Date()
    @Published var launchTime = Date()
    @Published var duration: Double = 0
    @Published var rapidClassification = "III"
    @Published var mileage: Double = 0
    @Published var flowValue: Double = 0
    @Published var flowUnit = "CFS"
    @Published var selectedPhotos: [UIImage] = []
    
    // Dropdown options
    let craftTypes = ["Raft", "Kayak", "SUP", "Canoe", "Cat", "Duckie", "Packraft"]
    let classifications = ["I", "II", "III", "IV", "V", "VI"]
    let flowUnits = ["CFS", "Feet"]
    
    // Validation
    var isValid: Bool {
        !title.isEmpty && !sectionName.isEmpty && mileage > 0
    }
    
    // Save function
    func save(context: NSManagedObjectContext) {
        let activity = RiverActivity(context: context)
        activity.id = UUID()
        activity.title = title
        activity.activityDescription = activityDescription.isEmpty ? nil : activityDescription
        activity.sectionName = sectionName
        activity.craftType = craftType
        activity.date = date
        activity.launchTime = launchTime
        activity.duration = duration
        activity.rapidClassification = rapidClassification
        activity.mileage = mileage
        activity.flowValue = flowValue
        activity.flowUnit = flowUnit
        
        // Convert photos to Data array
        if !selectedPhotos.isEmpty {
            let photoDataArray = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            activity.photoData = photoDataArray as NSObject
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving activity: \(error)")
        }
    }
}
