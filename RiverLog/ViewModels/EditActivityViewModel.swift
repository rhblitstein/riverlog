import Foundation
import SwiftUI
import CoreData
import Combine

class EditActivityViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var activityDescription: String = ""
    @Published var craftType: String = "Raft"
    @Published var date: Date = Date()
    @Published var launchTime: Date = Date()
    @Published var duration: Double = 0
    @Published var flowValue: Double = 0
    @Published var flowUnit: String = "CFS"
    @Published var selectedPhotos: [UIImage] = []
    @Published var selectedSection: RiverSection? = nil
    
    let craftTypes = ["Raft", "Kayak", "Canoe", "SUP", "Duckie", "Cat", "Other"]
    let flowUnits = ["CFS", "Feet"]
    
    private var activity: RiverActivity
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(activity: RiverActivity) {
        self.activity = activity
        self.title = activity.title ?? ""
        self.activityDescription = activity.activityDescription ?? ""
        self.craftType = activity.craftType ?? "Raft"
        self.date = activity.date ?? Date()
        self.launchTime = activity.launchTime ?? Date()
        self.duration = activity.duration
        self.flowValue = activity.flowValue
        self.flowUnit = activity.flowUnit ?? "CFS"
        self.selectedSection = activity.section
        
        // Load existing photos
        if let photoDataArray = activity.photoData as? [Data] {
            self.selectedPhotos = photoDataArray.compactMap { UIImage(data: $0) }
        }
    }
    
    func save(context: NSManagedObjectContext, section: RiverSection?) {
        activity.title = title
        activity.activityDescription = activityDescription
        activity.craftType = craftType
        activity.date = date
        activity.launchTime = launchTime
        activity.duration = duration
        activity.flowValue = flowValue
        activity.flowUnit = flowUnit
        
        // Update section relationship
        activity.section = section
        
        // Save photos as JPEG data
        if !selectedPhotos.isEmpty {
            let photoDataArray = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            activity.photoData = photoDataArray as NSArray
        } else {
            activity.photoData = NSArray()
        }
        
        do {
            try context.save()
        } catch {
            print("Error updating activity: \(error)")
        }
    }
}
