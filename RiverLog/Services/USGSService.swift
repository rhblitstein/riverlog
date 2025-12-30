import Foundation

struct USGSFlowReading: Codable {
    let value: String
    let dateTime: String
    let qualifiers: [String]?
    
    var flowValue: Double? {
        guard let value = Double(value) else { return nil }
        // Filter out USGS invalid data codes
        if value < 0 || value > 100000 {
            return nil
        }
        return value
    }
    
    var hasIceQualifier: Bool {
        qualifiers?.contains("Ice") ?? false
    }
}

struct USGSValues: Codable {
    let value: [USGSFlowReading]
}

struct USGSTimeSeries: Codable {
    let values: [USGSValues]
}

struct USGSTimeSeriesResponse: Codable {
    let timeSeries: [USGSTimeSeries]?
}

struct USGSRoot: Codable {
    let value: USGSTimeSeriesResponse
}

enum FlowDataError: Error {
    case iceAffected
    case seasonallyClosed
    case noData
}

class USGSService {
    
    /// Fetch current flow for a USGS gauge
    /// - Parameter gaugeID: USGS site number (e.g., "07091200")
    /// - Returns: Current flow in CFS, or throws error with reason
    static func fetchCurrentFlow(gaugeID: String) async throws -> Double {
        print("🌊 Fetching flow for gauge: \(gaugeID)")
        
        // USGS Instantaneous Values API
        let urlString = "https://waterservices.usgs.gov/nwis/iv/?format=json&sites=\(gaugeID)&parameterCd=00060&siteStatus=all"
        
        print("📡 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response status: \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let root = try decoder.decode(USGSRoot.self, from: data)
        
        guard let timeSeries = root.value.timeSeries?.first,
              let values = timeSeries.values.first,
              let latestReading = values.value.first else {
            print("❌ No flow data found in structure")
            throw FlowDataError.noData
        }
        
        print("📊 Raw value from USGS: \(latestReading.value)")
        
        // Check for ice qualifier
        if latestReading.hasIceQualifier {
            print("❄️ Gauge is ice-affected")
            throw FlowDataError.iceAffected
        }
        
        // Check for seasonal closure (looking at qualifiers)
        if let qualifiers = latestReading.qualifiers,
           qualifiers.contains(where: { $0.lowercased().contains("season") }) {
            print("🍂 Gauge is seasonally closed")
            throw FlowDataError.seasonallyClosed
        }
        
        guard let flow = latestReading.flowValue else {
            print("❌ Flow value was invalid or negative")
            throw FlowDataError.noData
        }
        
        print("✅ Flow: \(flow) CFS")
        return flow
    }
}
