import Foundation

struct Section: Codable, Identifiable {
    let id: Int
    let riverId: Int
    let riverName: String
    let state: String
    let name: String
    let classRating: String?
    let gradient: Double?
    let gradientUnit: String?
    let mileage: Double?
    let putInName: String?
    let takeOutName: String?
    let gaugeName: String?
    let gaugeId: String?
    let flowMin: Double?
    let flowMax: Double?
    let flowLow: Double?
    let flowHigh: Double?
    let flowUnit: String?
    let awUrl: String?
    let awId: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case riverId = "river_id"
        case riverName = "river_name"
        case state, name
        case classRating = "class_rating"
        case gradient
        case gradientUnit = "gradient_unit"
        case mileage
        case putInName = "put_in_name"
        case takeOutName = "take_out_name"
        case gaugeName = "gauge_name"
        case gaugeId = "gauge_id"
        case flowMin = "flow_min"
        case flowMax = "flow_max"
        case flowLow = "flow_low"
        case flowHigh = "flow_high"
        case flowUnit = "flow_unit"
        case awUrl = "aw_url"
        case awId = "aw_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var displayName: String {
        "\(riverName) - \(name)"
    }
}

extension Section: Equatable {
    static func == (lhs: Section, rhs: Section) -> Bool {
        lhs.id == rhs.id
    }
}
