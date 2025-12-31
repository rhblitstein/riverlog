import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData
import Combine

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var isSyncing = false
    
    // MARK: - Sync Activity to Firestore
    func syncActivityToFirestore(activity: RiverActivity, context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Set userId if not already set
        if activity.userId == nil || activity.userId?.isEmpty == true {
            activity.userId = userId
        }
        
        // Create Firestore document
        let activityData: [String: Any] = [
            "title": activity.title ?? "",
            "notes": activity.notes ?? "",
            "tripReport": activity.tripReport ?? "",
            "privateNotes": activity.privateNotes ?? "",
            "tripType": activity.tripType ?? "",
            "craftType": activity.craftType ?? "",
            "lapType": activity.lapType ?? "",
            "loadSize": activity.loadSize,
            "date": Timestamp(date: activity.date ?? Date()),
            "launchTime": Timestamp(date: activity.launchTime ?? Date()),
            "duration": activity.duration,
            "flowValue": activity.flowValue,
            "flowUnit": activity.flowUnit ?? "CFS",
            "visibility": activity.visibility ?? "Public",
            "hideFlow": activity.hideFlow,
            "hideDuration": activity.hideDuration,
            "hidePhotos": activity.hidePhotos,
            "hideNotes": activity.hideNotes,
            "userId": userId,
            "lastSynced": Timestamp(date: Date()),
            // Section data (denormalized for easier querying)
            "sectionId": activity.section?.id?.uuidString ?? "",
            "sectionName": activity.section?.name ?? "",
            "riverName": activity.section?.riverName ?? "",
            // Gear data
            "gearId": activity.gear?.id?.uuidString ?? "",
            "gearName": activity.gear?.name ?? ""
        ]
        
        let docRef: DocumentReference
        
        if let firestoreId = activity.firestoreId, !firestoreId.isEmpty {
            // Update existing document
            docRef = db.collection("users").document(userId).collection("activities").document(firestoreId)
            try await docRef.setData(activityData, merge: true)
        } else {
            // Create new document
            docRef = db.collection("users").document(userId).collection("activities").document()
            try await docRef.setData(activityData)
            
            // Save Firestore ID back to Core Data
            await MainActor.run {
                activity.firestoreId = docRef.documentID
                activity.lastSynced = Date()
                try? context.save()
            }
        }
        
        // Upload photos if any
        if let photoDataArray = activity.photoData as? [Data], !photoDataArray.isEmpty {
            try await uploadPhotos(photoDataArray, activityId: docRef.documentID, userId: userId)
        }
    }
    
    // MARK: - Sync All Local Activities to Firestore
    func syncAllActivitiesToFirestore(context: NSManagedObjectContext) async throws {
        await MainActor.run { isSyncing = true }
        defer { Task { await MainActor.run { isSyncing = false } } }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let fetchRequest: NSFetchRequest<RiverActivity> = RiverActivity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ OR userId == nil", userId)
        
        let activities = try context.fetch(fetchRequest)
        
        for activity in activities {
            try await syncActivityToFirestore(activity: activity, context: context)
        }
    }
    
    // MARK: - Fetch Activities from Firestore
    func fetchActivitiesFromFirestore(context: NSManagedObjectContext) async throws {
        await MainActor.run { isSyncing = true }
        defer { Task { await MainActor.run { isSyncing = false } } }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("activities")
            .getDocuments()
        
        await MainActor.run {
            for document in snapshot.documents {
                let data = document.data()
                
                // Check if activity already exists in Core Data
                let fetchRequest: NSFetchRequest<RiverActivity> = RiverActivity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "firestoreId == %@", document.documentID)
                
                let existingActivities = try? context.fetch(fetchRequest)
                let activity: RiverActivity
                
                if let existing = existingActivities?.first {
                    activity = existing
                } else {
                    activity = RiverActivity(context: context)
                    activity.id = UUID()
                    activity.firestoreId = document.documentID
                }
                
                // Update activity from Firestore data
                activity.userId = userId
                activity.title = data["title"] as? String
                activity.notes = data["notes"] as? String
                activity.tripReport = data["tripReport"] as? String
                activity.privateNotes = data["privateNotes"] as? String
                activity.tripType = data["tripType"] as? String
                activity.craftType = data["craftType"] as? String
                activity.lapType = data["lapType"] as? String
                activity.loadSize = Int16(data["loadSize"] as? Int ?? 0)
                
                if let timestamp = data["date"] as? Timestamp {
                    activity.date = timestamp.dateValue()
                }
                if let timestamp = data["launchTime"] as? Timestamp {
                    activity.launchTime = timestamp.dateValue()
                }
                
                activity.duration = data["duration"] as? Double ?? 0
                activity.flowValue = data["flowValue"] as? Double ?? 0
                activity.flowUnit = data["flowUnit"] as? String
                activity.visibility = data["visibility"] as? String
                activity.hideFlow = data["hideFlow"] as? Bool ?? false
                activity.hideDuration = data["hideDuration"] as? Bool ?? false
                activity.hidePhotos = data["hidePhotos"] as? Bool ?? false
                activity.hideNotes = data["hideNotes"] as? Bool ?? false
                
                if let timestamp = data["lastSynced"] as? Timestamp {
                    activity.lastSynced = timestamp.dateValue()
                }
                
                // Link to section if exists
                if let sectionIdString = data["sectionId"] as? String,
                   let sectionUUID = UUID(uuidString: sectionIdString) {
                    let sectionFetch: NSFetchRequest<RiverSection> = RiverSection.fetchRequest()
                    sectionFetch.predicate = NSPredicate(format: "id == %@", sectionUUID as CVarArg)
                    activity.section = try? context.fetch(sectionFetch).first
                }
                
                // Link to gear if exists
                if let gearIdString = data["gearId"] as? String,
                   let gearUUID = UUID(uuidString: gearIdString) {
                    let gearFetch: NSFetchRequest<Gear> = Gear.fetchRequest()
                    gearFetch.predicate = NSPredicate(format: "id == %@", gearUUID as CVarArg)
                    activity.gear = try? context.fetch(gearFetch).first
                }
            }
            
            try? context.save()
        }
    }
    
    // MARK: - Delete Activity from Firestore
    func deleteActivityFromFirestore(firestoreId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        try await db.collection("users")
            .document(userId)
            .collection("activities")
            .document(firestoreId)
            .delete()
    }
    
    // MARK: - Upload Photos to Firebase Storage
    private func uploadPhotos(_ photos: [Data], activityId: String, userId: String) async throws {
        // We'll implement photo storage later - for now just skip
        // This would use Firebase Storage to upload images
    }
}
