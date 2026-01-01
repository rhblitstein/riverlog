import Foundation
import CoreData
import CoreLocation

class GPSDataService {

    /// Save GPS points to an activity
    func saveGPSPoints(
        locations: [CLLocation],
        to activity: RiverActivity,
        context: NSManagedObjectContext
    ) {
        guard !locations.isEmpty else { return }

        // Calculate aggregate stats
        var totalDistance: Double = 0
        var elevationGain: Double = 0
        var elevationLoss: Double = 0
        var previousLocation: CLLocation?
        var speedSum: Double = 0
        var movingPointsCount: Int = 0

        for location in locations {
            let gpsPoint = GPSPoint(context: context)
            gpsPoint.id = UUID()
            gpsPoint.latitude = location.coordinate.latitude
            gpsPoint.longitude = location.coordinate.longitude
            gpsPoint.altitude = location.altitude
            gpsPoint.timestamp = location.timestamp
            gpsPoint.speed = max(0, location.speed)
            gpsPoint.accuracy = location.horizontalAccuracy
            gpsPoint.heading = location.course >= 0 ? location.course : 0
            gpsPoint.isPaused = false
            gpsPoint.activity = activity

            // Track moving speed for average calculation
            if location.speed > 0.5 {
                speedSum += location.speed
                movingPointsCount += 1
            }

            if let prev = previousLocation {
                let distance = location.distance(from: prev)
                if distance > 2 && distance < 100 {  // Filter noise
                    totalDistance += distance

                    let elevDelta = location.altitude - prev.altitude
                    if elevDelta > 0 {
                        elevationGain += elevDelta
                    } else {
                        elevationLoss += abs(elevDelta)
                    }
                }
            }
            previousLocation = location
        }

        // Update activity with GPS stats
        activity.totalDistance = totalDistance
        activity.elevationGain = elevationGain
        activity.elevationLoss = elevationLoss
        activity.hasGPSData = true

        // Calculate average moving speed
        if movingPointsCount > 0 {
            activity.averageSpeed = speedSum / Double(movingPointsCount)
        }

        do {
            try context.save()
        } catch {
            print("Error saving GPS points: \(error)")
        }
    }

    /// Fetch GPS points for an activity
    func fetchGPSPoints(for activity: RiverActivity, context: NSManagedObjectContext) -> [GPSPoint] {
        let fetchRequest: NSFetchRequest<GPSPoint> = GPSPoint.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "activity == %@", activity)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \GPSPoint.timestamp, ascending: true)]

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching GPS points: \(error)")
            return []
        }
    }

    /// Convert GPSPoints to CLLocationCoordinate2D array for map display
    func getRouteCoordinates(for activity: RiverActivity, context: NSManagedObjectContext) -> [CLLocationCoordinate2D] {
        let points = fetchGPSPoints(for: activity, context: context)
        return points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// Calculate duration from GPS timestamps
    func calculateDuration(from locations: [CLLocation]) -> TimeInterval {
        guard let first = locations.first?.timestamp,
              let last = locations.last?.timestamp else { return 0 }
        return last.timeIntervalSince(first)
    }

    /// Calculate distance from GPS points in miles (when no section selected)
    func calculateDistanceInMiles(from locations: [CLLocation]) -> Double {
        var totalDistance: Double = 0
        var previousLocation: CLLocation?

        for location in locations {
            if let prev = previousLocation {
                totalDistance += location.distance(from: prev)
            }
            previousLocation = location
        }

        return totalDistance / 1609.34  // Convert meters to miles
    }

    /// Get bounding region for a route
    func getBoundingRegion(for coordinates: [CLLocationCoordinate2D]) -> (center: CLLocationCoordinate2D, span: (latDelta: Double, lonDelta: Double))? {
        guard !coordinates.isEmpty else { return nil }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        // Add some padding
        let latDelta = (maxLat - minLat) * 1.3
        let lonDelta = (maxLon - minLon) * 1.3

        return (center: center, span: (latDelta: max(latDelta, 0.005), lonDelta: max(lonDelta, 0.005)))
    }

    /// Delete GPS points for an activity
    func deleteGPSPoints(for activity: RiverActivity, context: NSManagedObjectContext) {
        let points = fetchGPSPoints(for: activity, context: context)
        for point in points {
            context.delete(point)
        }

        activity.hasGPSData = false
        activity.totalDistance = 0
        activity.averageSpeed = 0
        activity.elevationGain = 0
        activity.elevationLoss = 0

        do {
            try context.save()
        } catch {
            print("Error deleting GPS points: \(error)")
        }
    }
}
