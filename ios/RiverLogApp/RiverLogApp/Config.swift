struct Config {
    #if DEBUG
    static let apiBaseURL = "http://localhost:8080/api/v1"
    #else
    static let apiBaseURL = "https://your-production-url.com/api/v1"
    #endif
}
