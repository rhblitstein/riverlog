import Foundation
import CoreData
import Combine
import UIKit

class EditActivityViewModel: ObservableObject {
    let activity: RiverActivity
    
    // Form fields
    @Published var title: String
    @Published var activityDescription: String
    @Published var sectionName: String
    @Published var craftType: String
    @Published var date: Date
    @Published var launchTime: Date
    @Published var duration: Double
    @Published var rapidClassification: String
    @Published var mileage: Double
    @Published var flowValue: Double
    @Published var flowUnit: String
    @Published var selectedPhotos: [UIImage] = []
    
    // Dropdown options
    let craftTypes = ["Raft", "Kayak", "SUP", "Canoe", "Cat", "Duckie", "Packraft"]
    let classifications = ["I", "II", "III", "IV", "V", "VI"]
    let flowUnits = ["CFS", "Feet"]
    
    // Validation
    var isValid: Bool {
        !title.isEmpty && !sectionName.isEmpty && mileage > 0
    }
    
    init(activity: RiverActivity) {
        self.activity = activity
        self.title = activity.title ?? ""
        self.activityDescription = activity.activityDescription ?? ""
        self.sectionName = activity.sectionName ?? ""
        self.craftType = activity.craftType ?? "Raft"
        self.date = activity.date ?? Date()
        self.launchTime = activity.launchTime ?? Date()
        self.duration = activity.duration
        self.rapidClassification = activity.rapidClassification ?? "III"
        self.mileage = activity.mileage
        self.flowValue = activity.flowValue
        self.flowUnit = activity.flowUnit ?? "CFS"
        
        // Load existing photos
        if let photoDataArray = activity.photoData as? [Data] {
            self.selectedPhotos = photoDataArray.compactMap { UIImage(data: $0) }
        }
    }
    
    // Save function
    func save(context: NSManagedObjectContext) {
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
        
        // Update photos
        if !selectedPhotos.isEmpty {
            let photoDataArray = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            activity.photoData = photoDataArray as NSObject
        } else {
            activity.photoData = nil
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving activity: \(error)")
        }
    }
    
    // Delete function
    func delete(context: NSManagedObjectContext) {
        context.delete(activity)
        
        do {
            try context.save()
        } catch {
            print("Error deleting activity: \(error)")
        }
    }
}
