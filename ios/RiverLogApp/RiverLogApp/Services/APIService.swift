import Foundation


class APIService {
    static let shared = APIService()
    
    private let baseURL = Config.apiBaseURL
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private init() {}
    
    // MARK: - Auth
    
    func register(email: String, password: String, firstName: String?, lastName: String?) async throws -> User {
        let request = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        
        let response: APIResponse<User> = try await post(endpoint: "/auth/register", body: request)
        return response.data
    }
    
    func login(email: String, password: String) async throws -> AuthToken {
        let request = LoginRequest(email: email, password: password)
        let response: APIResponse<AuthToken> = try await post(endpoint: "/auth/login", body: request)
        return response.data
    }
    
    // MARK: - Trips
    
    func getTrips(token: String) async throws -> [Trip] {
        let response: APIResponse<TripsResponse> = try await get(endpoint: "/trips", token: token)
        return response.data.trips ?? []
    }
    
    func getTrip(id: Int, token: String) async throws -> Trip {
        let response: APIResponse<Trip> = try await get(endpoint: "/trips/\(id)", token: token)
        return response.data
    }
    
    func createTrip(trip: CreateTripRequest, token: String) async throws -> Trip {
        let response: APIResponse<Trip> = try await post(endpoint: "/trips", body: trip, token: token)
        return response.data
    }
    
    func updateTrip(id: Int, trip: CreateTripRequest, token: String) async throws -> Trip {
        let response: APIResponse<Trip> = try await put(endpoint: "/trips/\(id)", body: trip, token: token)
        return response.data
    }
    
    func deleteTrip(id: Int, token: String) async throws {
        try await delete(endpoint: "/trips/\(id)", token: token)
    }
    
    // MARK: - User
    
    func getCurrentUser(token: String) async throws -> User {
        let response: APIResponse<User> = try await get(endpoint: "/users/me", token: token)
        return response.data
    }
    
    // MARK: - HTTP Methods
    
    private func get<T: Decodable>(endpoint: String, token: String? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await performRequest(request)
    }
    
    private func post<T: Decodable, B: Encodable>(endpoint: String, body: B, token: String? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    private func put<T: Decodable, B: Encodable>(endpoint: String, body: B, token: String? = nil) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(body)
        
        return try await performRequest(request)
    }
    
    private func delete(endpoint: String, token: String? = nil) async throws {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        if httpResponse.statusCode == 204 {
            return // Success, no content
        }
        
        if httpResponse.statusCode >= 400 {
            throw APIError.serverError("Delete failed")
        }
    }
    
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode >= 400 {
                if let errorResponse = try? decoder.decode(BackendError.self, from: data) {
                    throw APIError.serverError(errorResponse.error)
                }
                throw APIError.serverError("Server error: \(httpResponse.statusCode)")
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                throw APIError.decodingError
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
