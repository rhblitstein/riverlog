import Foundation
import SwiftUI
import CoreData
import Combine
import FirebaseAuth

class AddActivityViewModel: ObservableObject {
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
    @Published var isFetchingFlow: Bool = false
    @Published var flowErrorMessage: String? = nil
    @Published var visibility: VisibilityType = .public
    @Published var hideFlow: Bool = false
    @Published var hideDuration: Bool = false
    @Published var hidePhotos: Bool = false
    @Published var hideNotes: Bool = false
    @Published var didSwim: Bool = false
    @Published var hadCarnage: Bool = false

    let flowUnits = ["CFS", "Feet"]
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var availableLapTypes: [LapType] {
        if let gear = selectedGear, let gearCraftType = CraftType(rawValue: gear.craftType ?? "") {
            return gearCraftType.availableLapTypes
        }
        return craftType.availableLapTypes
    }
    
    // When gear is selected, auto-populate craft and lap type
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
    
    func fetchFlow(gaugeID: String) async {
        print("🎯 Starting flow fetch for gauge: \(gaugeID)")
        await MainActor.run {
            isFetchingFlow = true
            flowErrorMessage = nil
        }
        
        do {
            let flow = try await USGSService.fetchCurrentFlow(gaugeID: gaugeID)
            print("💧 Got flow: \(flow)")
            await MainActor.run {
                self.flowValue = flow
                self.flowUnit = "CFS"
                self.isFetchingFlow = false
                self.flowErrorMessage = nil
            }
        } catch FlowDataError.iceAffected {
            await MainActor.run {
                self.isFetchingFlow = false
                self.flowErrorMessage = "Gauge is ice-affected"
            }
        } catch FlowDataError.seasonallyClosed {
            await MainActor.run {
                self.isFetchingFlow = false
                self.flowErrorMessage = "Gauge is seasonally closed"
            }
        } catch FlowDataError.noData {
            await MainActor.run {
                self.isFetchingFlow = false
                self.flowErrorMessage = "No flow data available"
            }
        } catch {
            print("❌ Error fetching flow: \(error)")
            await MainActor.run {
                self.isFetchingFlow = false
                self.flowErrorMessage = "Unable to fetch flow data"
            }
        }
    }
    
    func save(context: NSManagedObjectContext, section: RiverSection?) {
        let activity = RiverActivity(context: context)
        activity.id = UUID()
        activity.userId = Auth.auth().currentUser?.uid ?? ""
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
        activity.didSwim = didSwim
        activity.hadCarnage = hadCarnage

        // Associate with gear and section
        activity.gear = selectedGear
        activity.section = section
        
        // Save photos as JPEG data
        if !selectedPhotos.isEmpty {
            let photoDataArray = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            activity.photoData = photoDataArray as NSArray
        }
        
        do {
            try context.save()
            
            // Sync to Firestore
            Task {
                let firestoreService = FirestoreService()
                try? await firestoreService.syncActivityToFirestore(activity: activity, context: context)
            }
        } catch {
            print("Error saving activity: \(error)")
        }
    }
}
