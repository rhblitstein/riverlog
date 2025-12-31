import Foundation
import SwiftUI
import CoreData
import Combine

class EditActivityViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var notes: String = ""
    @Published var tripReport: String = ""
    @Published var privateNotes: String = ""
    @Published var tripType: TripType = .private
    @Published var selectedGear: Gear? = nil
    @Published var craftType: CraftType = .raft
    @Published var lapType: LapType? = nil
    @Published var loadSize: Int = 0
    @Published var date: Date = Date()
    @Published var launchTime: Date = Date()
    @Published var duration: Double = 0
    @Published var flowValue: Double = 0
    @Published var flowUnit: String = "CFS"
    @Published var selectedPhotos: [UIImage] = []
    @Published var selectedSection: RiverSection? = nil
    @Published var visibility: VisibilityType = .public
    @Published var hideFlow: Bool = false
    @Published var hideDuration: Bool = false
    @Published var hidePhotos: Bool = false
    @Published var hideNotes: Bool = false
    
    let flowUnits = ["CFS", "Feet"]
    
    private var activity: RiverActivity
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var availableLapTypes: [LapType] {
        if let gear = selectedGear, let gearCraftType = CraftType(rawValue: gear.craftType ?? "") {
            return gearCraftType.availableLapTypes
        }
        return craftType.availableLapTypes
    }
    
    init(activity: RiverActivity) {
        self.activity = activity
        self.title = activity.title ?? ""
        self.notes = activity.notes ?? ""
        self.tripReport = activity.tripReport ?? ""
        self.privateNotes = activity.privateNotes ?? ""
        self.tripType = TripType(rawValue: activity.tripType ?? "Private") ?? .private
        self.selectedGear = activity.gear
        self.craftType = CraftType(rawValue: activity.craftType ?? "Raft") ?? .raft
        self.lapType = activity.lapType != nil ? LapType(rawValue: activity.lapType!) : nil
        self.loadSize = Int(activity.loadSize)
        self.date = activity.date ?? Date()
        self.launchTime = activity.launchTime ?? Date()
        self.duration = activity.duration
        self.flowValue = activity.flowValue
        self.flowUnit = activity.flowUnit ?? "CFS"
        self.selectedSection = activity.section
        self.visibility = VisibilityType(rawValue: activity.visibility ?? "Public") ?? .public
        self.hideFlow = activity.hideFlow
        self.hideDuration = activity.hideDuration
        self.hidePhotos = activity.hidePhotos
        self.hideNotes = activity.hideNotes
        
        // Load existing photos
        if let photoDataArray = activity.photoData as? [Data] {
            self.selectedPhotos = photoDataArray.compactMap { UIImage(data: $0) }
        }
    }
    
    func selectGear(_ gear: Gear?) {
        self.selectedGear = gear
        if let gear = gear {
            if let gearCraftType = CraftType(rawValue: gear.craftType ?? "") {
                self.craftType = gearCraftType
            }
            if let defaultLap = gear.defaultLapType, let lapType = LapType(rawValue: defaultLap) {
                self.lapType = lapType
            }
            self.loadSize = Int(gear.defaultLoadSize)
        }
    }
    
    func save(context: NSManagedObjectContext, section: RiverSection?) {
        activity.title = title
        activity.notes = notes
        activity.tripReport = tripReport.isEmpty ? nil : tripReport
        activity.privateNotes = privateNotes.isEmpty ? nil : privateNotes
        activity.tripType = tripType.rawValue
        activity.craftType = craftType.rawValue
        activity.lapType = lapType?.rawValue
        activity.loadSize = Int16(loadSize)
        activity.date = date
        activity.launchTime = launchTime
        activity.duration = duration
        activity.flowValue = flowValue
        activity.flowUnit = flowUnit
        activity.visibility = visibility.rawValue
        activity.hideFlow = hideFlow
        activity.hideDuration = hideDuration
        activity.hidePhotos = hidePhotos
        activity.hideNotes = hideNotes
        
        // Update relationships
        activity.gear = selectedGear
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
