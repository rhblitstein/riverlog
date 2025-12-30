import Foundation
import SwiftUI
import CoreData
import Combine

class AddActivityViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var activityDescription: String = ""
    @Published var craftType: String = "Raft"
    @Published var date: Date = Date()
    @Published var launchTime: Date = Date()
    @Published var duration: Double = 0
    @Published var flowValue: Double = 0
    @Published var flowUnit: String = "CFS"
    @Published var selectedPhotos: [UIImage] = []
    @Published var isFetchingFlow: Bool = false
    @Published var flowErrorMessage: String? = nil
    
    let craftTypes = ["Raft", "Kayak", "Canoe", "SUP", "Duckie", "Cat", "Other"]
    let flowUnits = ["CFS", "Feet"]
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
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
        activity.title = title
        activity.activityDescription = activityDescription
        activity.craftType = craftType
        activity.date = date
        activity.launchTime = launchTime
        activity.duration = duration
        activity.flowValue = flowValue
        activity.flowUnit = flowUnit
        
        // Associate with the selected section
        activity.section = section
        
        // Save photos as JPEG data
        if !selectedPhotos.isEmpty {
            let photoDataArray = selectedPhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            activity.photoData = photoDataArray as NSArray
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving activity: \(error)")
        }
    }
}
