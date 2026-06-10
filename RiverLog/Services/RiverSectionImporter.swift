import Foundation
import CoreData

struct RiverSectionJSON: Codable {
    let id: String
    let name: String
    let riverName: String
    let state: String
    let classRating: String
    let gradient: Double?
    let gradientUnit: String
    let mileage: Double?
    let putInName: String
    let takeOutName: String
    let gaugeName: String
    let gaugeID: String
    let awURL: String
    let putInLatitude: Double?
    let putInLongitude: Double?
    let takeOutLatitude: Double?
    let takeOutLongitude: Double?
}

class RiverSectionImporter {
    
    static func importSections(context: NSManagedObjectContext) {
        // Check if already imported
        let fetchRequest: NSFetchRequest<RiverSection> = RiverSection.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        if let count = try? context.count(for: fetchRequest), count > 0 {
            // Check if coordinates need updating (existing data without coords)
            let noCoordsFetch: NSFetchRequest<RiverSection> = RiverSection.fetchRequest()
            noCoordsFetch.predicate = NSPredicate(format: "putInLatitude == 0 AND isCustom == NO")
            noCoordsFetch.fetchLimit = 1
            if let noCoords = try? context.count(for: noCoordsFetch), noCoords > 0 {
                print("Updating sections with coordinates...")
                updateCoordinates(context: context)
            } else {
                print("River sections already imported, skipping...")
            }
            return
        }
        
        guard let url = Bundle.main.url(forResource: "river_sections", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load river_sections.json")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let sections = try decoder.decode([RiverSectionJSON].self, from: data)
            
            print("Importing \(sections.count) river sections...")
            
            for sectionData in sections {
                let section = RiverSection(context: context)
                section.id = UUID() // Generate our own UUID
                section.name = sectionData.name
                section.riverName = sectionData.riverName
                section.state = sectionData.state
                section.classRating = sectionData.classRating
                section.gradient = sectionData.gradient ?? 0
                section.gradientUnit = sectionData.gradientUnit
                section.mileage = sectionData.mileage ?? 0
                section.putInName = sectionData.putInName
                section.takeOutName = sectionData.takeOutName
                section.gaugeName = sectionData.gaugeName
                section.gaugeID = sectionData.gaugeID
                section.awURL = sectionData.awURL
                section.putInLatitude = sectionData.putInLatitude ?? 0
                section.putInLongitude = sectionData.putInLongitude ?? 0
                section.takeOutLatitude = sectionData.takeOutLatitude ?? 0
                section.takeOutLongitude = sectionData.takeOutLongitude ?? 0
            }
            
            try context.save()
            print("Successfully imported \(sections.count) river sections!")
            
        } catch {
            print("Failed to import river sections: \(error)")
        }
    }

    /// Update existing sections with coordinate data from the JSON
    static func updateCoordinates(context: NSManagedObjectContext) {
        guard let url = Bundle.main.url(forResource: "river_sections", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        do {
            let decoder = JSONDecoder()
            let jsonSections = try decoder.decode([RiverSectionJSON].self, from: data)

            // Build lookup by AW ID (stored in awURL)
            let lookup = Dictionary(uniqueKeysWithValues: jsonSections.compactMap { s -> (String, RiverSectionJSON)? in
                return (s.id, s)
            })

            let fetchRequest: NSFetchRequest<RiverSection> = RiverSection.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "putInLatitude == 0 AND isCustom == NO")
            let sections = try context.fetch(fetchRequest)

            var updated = 0
            for section in sections {
                // Match by AW URL suffix
                if let awURL = section.awURL,
                   let awID = awURL.split(separator: "/").last.map(String.init),
                   let jsonSection = lookup[awID] {
                    section.putInLatitude = jsonSection.putInLatitude ?? 0
                    section.putInLongitude = jsonSection.putInLongitude ?? 0
                    section.takeOutLatitude = jsonSection.takeOutLatitude ?? 0
                    section.takeOutLongitude = jsonSection.takeOutLongitude ?? 0
                    updated += 1
                }
            }

            try context.save()
            print("Updated coordinates for \(updated) sections")
        } catch {
            print("Failed to update coordinates: \(error)")
        }
    }
}
