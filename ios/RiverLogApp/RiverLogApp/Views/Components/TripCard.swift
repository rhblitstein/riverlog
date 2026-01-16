import SwiftUI

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 12) {
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(trip.riverName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(trip.sectionName)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if let difficulty = trip.difficulty {
                    Text(difficulty)
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary)
                        .foregroundColor(Color(.systemBackground))
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 16) {
                if let flow = trip.flow {
                    Label("\(flow) \(trip.flowUnit ?? "cfs")", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let mileage = trip.mileage {
                    Label(String(format: "%.1f mi", mileage), systemImage: "ruler")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
                
                if let craft = trip.craftType {
                    Text("\(craftEmoji(for: craft)) \(craft.capitalized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary, lineWidth: 2)
        )
    }
    
    private var formattedDate: String {
        guard let date = trip.formattedDate else { return trip.tripDate }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Yesterday at \(formatter.string(from: date))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    private func craftEmoji(for craftType: String) -> String {
        switch craftType.lowercased() {
        case "kayak", "packraft":
            return "🛶"
        case "raft":
            return "🚣"
        case "canoe":
            return "🛶"
        case "cataraft":
            return "😸"
        case "sup", "paddleboard":
            return "🏄"
        default:
            return "🚣"
        }
    }
}
