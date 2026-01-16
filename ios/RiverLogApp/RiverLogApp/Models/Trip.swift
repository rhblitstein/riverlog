import Foundation

struct Trip: Codable, Identifiable {
    let id: Int
    let userId: Int
    let riverName: String
    let sectionName: String
    let tripDate: String // YYYY-MM-DD
    let difficulty: String?
    let flow: Int?
    let flowUnit: String?
    let craftType: String?
    let durationMinutes: Int?
    let mileage: Double?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case riverName = "river_name"
        case sectionName = "section_name"
        case tripDate = "trip_date"
        case difficulty, flow
        case flowUnit = "flow_unit"
        case craftType = "craft_type"
        case durationMinutes = "duration_minutes"
        case mileage, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var formattedDate: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: tripDate)
    }
}

struct CreateTripRequest: Codable {
    let riverName: String
    let sectionName: String
    let tripDate: String
    let difficulty: String?
    let flow: Int?
    let flowUnit: String?
    let craftType: String?
    let durationMinutes: Int?
    let mileage: Double?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case riverName = "river_name"
        case sectionName = "section_name"
        case tripDate = "trip_date"
        case difficulty, flow
        case flowUnit = "flow_unit"
        case craftType = "craft_type"
        case durationMinutes = "duration_minutes"
        case mileage, notes
    }
}
