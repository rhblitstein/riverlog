import SwiftUI

struct ActivityCardView: View {
    let activity: RiverActivity
    
    var formattedDate: String {
        guard let date = activity.date else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    func craftIcon(for craftType: String) -> String {
        switch craftType {
        case "Raft": return "🚣"
        case "Kayak": return "🛶"
        case "SUP": return "🏄"
        case "Canoe": return "🛶"
        case "Cat": return "⛵"
        case "Duckie": return "🦆"
        case "Packraft": return "🎒"
        default: return "🌊"
        }
    }
    
    var photos: [UIImage] {
        if let photoDataArray = activity.photoData as? [Data] {
            return photoDataArray.compactMap { UIImage(data: $0) }
        }
        return []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Date
                Text(formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                // Section name with craft icon
                HStack(spacing: 4) {
                    Text(craftIcon(for: activity.craftType ?? ""))
                        .font(.system(size: 12))
                    Text(activity.sectionName ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                // Title
                Text(activity.title ?? "Untitled")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Description
                if let description = activity.activityDescription, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Stats row
                HStack(spacing: 24) {
                    StatColumn(label: "Distance", value: String(format: "%.1f mi", activity.mileage))
                    StatColumn(label: "Time", value: String(format: "%.1f hr", activity.duration))
                    StatColumn(label: "Class", value: activity.rapidClassification ?? "-")
                }
                .padding(.top, 4)
            }
            .padding(16)
            
            // Photo carousel
            if !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photos.indices, id: \.self) { index in
                            Image(uiImage: photos[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 150)
                                .clipped()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground)
    }
}

struct StatColumn: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.light)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}
