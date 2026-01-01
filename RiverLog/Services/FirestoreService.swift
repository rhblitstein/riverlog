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
            "didSwim": activity.didSwim,
            "hadCarnage": activity.hadCarnage,
            "userId": userId,
            "lastSynced": Timestamp(date: Date()),
            // Section data (denormalized for easier querying)
            "sectionId": activity.section?.id?.uuidString ?? "",
            "sectionName": activity.section?.name ?? "",
            "riverName": activity.section?.riverName ?? "",
            // Gear data
            "gearId": activity.gear?.id?.uuidString ?? "",
            "gearName": activity.gear?.name ?? "",
            // GPS data
            "hasGPSData": activity.hasGPSData,
            "totalDistance": activity.totalDistance,
            "averageSpeed": activity.averageSpeed,
            "elevationGain": activity.elevationGain,
            "elevationLoss": activity.elevationLoss
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
                activity.didSwim = data["didSwim"] as? Bool ?? false
                activity.hadCarnage = data["hadCarnage"] as? Bool ?? false
                activity.hasGPSData = data["hasGPSData"] as? Bool ?? false
                activity.totalDistance = data["totalDistance"] as? Double ?? 0
                activity.averageSpeed = data["averageSpeed"] as? Double ?? 0
                activity.elevationGain = data["elevationGain"] as? Double ?? 0
                activity.elevationLoss = data["elevationLoss"] as? Double ?? 0

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
    
    // MARK: - Sync Gear to Firestore
    func syncGearToFirestore(gear: Gear, context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "FirestoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let gearData: [String: Any] = [
            "name": gear.name ?? "",
            "craftType": gear.craftType ?? "",
            "brand": gear.brand ?? "",
            "model": gear.model ?? "",
            "length": gear.length,
            "defaultLapType": gear.defaultLapType ?? "",
            "defaultLoadSize": gear.defaultLoadSize,
            "retired": gear.retired,
            "userId": userId,
            "lastSynced": Timestamp(date: Date())
        ]
        
        let docRef: DocumentReference
        
        if let firestoreId = gear.firestoreId, !firestoreId.isEmpty {
            // Update existing document
            docRef = db.collection("users").document(userId).collection("gear").document(firestoreId)
            try await docRef.setData(gearData, merge: true)
        } else {
            // Create new document
            docRef = db.collection("users").document(userId).collection("gear").document()
            try await docRef.setData(gearData)
            
            // Save Firestore ID back to Core Data
            await MainActor.run {
                gear.firestoreId = docRef.documentID
                gear.lastSynced = Date()
                try? context.save()
            }
        }
    }

    // MARK: - Fetch Gear from Firestore
    func fetchGearFromFirestore(context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("gear")
            .getDocuments()
        
        await MainActor.run {
            for document in snapshot.documents {
                let data = document.data()
                
                // Check if gear already exists in Core Data
                let fetchRequest: NSFetchRequest<Gear> = Gear.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "firestoreId == %@", document.documentID)
                
                let existingGear = try? context.fetch(fetchRequest)
                let gear: Gear
                
                if let existing = existingGear?.first {
                    gear = existing
                } else {
                    gear = Gear(context: context)
                    gear.id = UUID()
                    gear.firestoreId = document.documentID
                }
                
                // Update gear from Firestore data
                gear.name = data["name"] as? String
                gear.craftType = data["craftType"] as? String
                gear.brand = data["brand"] as? String
                gear.model = data["model"] as? String
                gear.length = data["length"] as? Double ?? 0
                gear.defaultLapType = data["defaultLapType"] as? String
                gear.defaultLoadSize = Int16(data["defaultLoadSize"] as? Int ?? 0)
                gear.retired = data["retired"] as? Bool ?? false
                
                if let timestamp = data["lastSynced"] as? Timestamp {
                    gear.lastSynced = timestamp.dateValue()
                }
            }
            
            try? context.save()
        }
    }

    // MARK: - Delete Gear from Firestore
    func deleteGearFromFirestore(firestoreId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        try await db.collection("users")
            .document(userId)
            .collection("gear")
            .document(firestoreId)
            .delete()
    }

    // MARK: - Sync GPS Points to Firestore
    func syncGPSPointsToFirestore(activity: RiverActivity, context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let firestoreId = activity.firestoreId,
              !firestoreId.isEmpty else { return }

        // Fetch GPS points from Core Data
        let fetchRequest: NSFetchRequest<GPSPoint> = GPSPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "activity == %@", activity)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GPSPoint.timestamp, ascending: true)]

        let points = try context.fetch(fetchRequest)
        guard !points.isEmpty else { return }

        let gpsCollection = db.collection("users")
            .document(userId)
            .collection("activities")
            .document(firestoreId)
            .collection("gpsPoints")

        // Delete existing points first
        let existingPoints = try await gpsCollection.getDocuments()
        for doc in existingPoints.documents {
            try await doc.reference.delete()
        }

        // Add new points in batches (Firestore batch limit is 500)
        let batchSize = 400
        for startIndex in stride(from: 0, to: points.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, points.count)
            let batch = db.batch()

            for i in startIndex..<endIndex {
                let point = points[i]
                let pointData: [String: Any] = [
                    "latitude": point.latitude,
                    "longitude": point.longitude,
                    "altitude": point.altitude,
                    "timestamp": Timestamp(date: point.timestamp ?? Date()),
                    "speed": point.speed,
                    "accuracy": point.accuracy,
                    "heading": point.heading,
                    "isPaused": point.isPaused
                ]
                let docRef = gpsCollection.document()
                batch.setData(pointData, forDocument: docRef)
            }

            try await batch.commit()
        }
    }

    // MARK: - Fetch GPS Points from Firestore
    func fetchGPSPointsFromFirestore(activity: RiverActivity, context: NSManagedObjectContext) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let firestoreId = activity.firestoreId,
              !firestoreId.isEmpty,
              activity.hasGPSData else { return }

        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("activities")
            .document(firestoreId)
            .collection("gpsPoints")
            .order(by: "timestamp")
            .getDocuments()

        await MainActor.run {
            // Delete existing local GPS points for this activity
            let existingFetch: NSFetchRequest<GPSPoint> = GPSPoint.fetchRequest()
            existingFetch.predicate = NSPredicate(format: "activity == %@", activity)
            if let existingPoints = try? context.fetch(existingFetch) {
                for point in existingPoints {
                    context.delete(point)
                }
            }

            // Create new GPS points from Firestore
            for document in snapshot.documents {
                let data = document.data()

                let point = GPSPoint(context: context)
                point.id = UUID()
                point.latitude = data["latitude"] as? Double ?? 0
                point.longitude = data["longitude"] as? Double ?? 0
                point.altitude = data["altitude"] as? Double ?? 0
                point.speed = data["speed"] as? Double ?? 0
                point.accuracy = data["accuracy"] as? Double ?? 0
                point.heading = data["heading"] as? Double ?? 0
                point.isPaused = data["isPaused"] as? Bool ?? false

                if let timestamp = data["timestamp"] as? Timestamp {
                    point.timestamp = timestamp.dateValue()
                }

                point.activity = activity
            }

            try? context.save()
        }
    }
}
