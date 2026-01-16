import Foundation

struct River: Codable, Identifiable {
    let id: Int
    let name: String
    let state: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, state
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
