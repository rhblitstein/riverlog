import Foundation

// MARK: - Response Wrappers

struct APIResponse<T: Codable>: Codable {
    let data: T
    let message: String?
}

struct TripsResponse: Codable {
    let trips: [Trip]?
    let total: Int?
    let limit: Int?
    let offset: Int?
}

struct SectionsResponse: Codable {
    let sections: [Section]?
    let total: Int?
}

struct RiversResponse: Codable {
    let rivers: [River]?
    let total: Int?
}

// MARK: - Errors

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkError(Error)
}

struct BackendError: Codable {
    let error: String
}
