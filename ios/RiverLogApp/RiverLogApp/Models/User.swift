import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String?
    let lastName: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var displayName: String {
        if let first = firstName, !first.isEmpty, let last = lastName, !last.isEmpty {
            return first + " " + last
        }
        return email
    }
}
