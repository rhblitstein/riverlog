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
}

class RiverSectionImporter {
    
    static func importSections(context: NSManagedObjectContext) {
        // Check if already imported
        let fetchRequest: NSFetchRequest<RiverSection> = RiverSection.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        if let count = try? context.count(for: fetchRequest), count > 0 {
            print("River sections already imported, skipping...")
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
            }
            
            try context.save()
            print("Successfully imported \(sections.count) river sections!")
            
        } catch {
            print("Failed to import river sections: \(error)")
        }
    }
}
