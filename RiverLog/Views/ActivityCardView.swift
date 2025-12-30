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
    
    func formatClassRating(_ rating: String) -> String {
        var formatted = rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "standout", with: "(")
        
        // Add closing parenthesis if we added an opening one
        if formatted.contains("(") && !formatted.contains(")") {
            formatted += ")"
        }
        
        return formatted
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
                
                // River and section name with craft icon
                HStack(spacing: 4) {
                    Text(craftIcon(for: activity.craftType ?? ""))
                        .font(.system(size: 12))
                    
                    if let section = activity.section {
                        Text("\(section.riverName ?? "") - \(section.name ?? "")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("No section selected")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
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
                    if let section = activity.section, section.mileage > 0 {
                        StatColumn(label: "Distance", value: String(format: "%.1f mi", section.mileage))
                    } else {
                        StatColumn(label: "Distance", value: "-")
                    }
                    
                    if activity.duration > 0 {
                        StatColumn(label: "Time", value: String(format: "%.1f hr", activity.duration))
                    } else {
                        StatColumn(label: "Time", value: "-")
                    }
                    
                    if let section = activity.section, let classRating = section.classRating {
                        StatColumn(label: "Class", value: formatClassRating(classRating))
                    } else {
                        StatColumn(label: "Class", value: "-")
                    }
                }
                .padding(.top, 4)
            }
            .padding(16)
            
            // Photo carousel
            if !photos.isEmpty {
                if photos.count == 1 {
                    // Single photo - full width
                    Image(uiImage: photos[0])
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                } else {
                    // Multiple photos - horizontal scroll
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
