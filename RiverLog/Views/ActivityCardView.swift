import SwiftUI

struct ActivityCardView: View {
    let activity: RiverActivity
    var userName: String = ""

    var formattedDateTime: String {
        guard let date = activity.date else { return "" }
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let time = timeFormatter.string(from: date)

        if calendar.isDateInToday(date) {
            return "Today at \(time)"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday at \(time)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "\(dateFormatter.string(from: date)) at \(time)"
        }
    }

    func craftIcon(for craftType: String) -> String {
        switch craftType {
        case "Raft": return "🚣"
        case "Kayak": return "🛶"
        case "SUP": return "🏄"
        case "Canoe": return "🛶"
        case "Cat": return "😸"
        case "Duckie": return "🦆"
        case "IK": return "🎒"
        default: return "🌊"
        }
    }

    func formatClassRating(_ rating: String) -> String {
        var formatted = rating
            .replacingOccurrences(of: "to", with: "-")
            .replacingOccurrences(of: "plus", with: "+")
            .replacingOccurrences(of: "minus", with: "-")
            .replacingOccurrences(of: "standout", with: "(")
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
            // User row
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(userName.isEmpty ? "You" : userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(formattedDateTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let section = activity.section {
                        HStack(spacing: 4) {
                            Text(craftIcon(for: activity.craftType ?? ""))
                                .font(.system(size: 11))
                            Text("\(section.riverName ?? "") - \(section.name ?? "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Title
            Text(activity.title ?? "Untitled")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            // Stats row
            HStack(spacing: 24) {
                if let section = activity.section, section.mileage > 0 {
                    StatColumn(label: "Distance", value: String(format: "%.1f mi", section.mileage))
                } else {
                    StatColumn(label: "Distance", value: "-")
                }

                if !activity.hideDuration, activity.duration > 0 {
                    let h = Int(activity.duration)
                    let m = Int((activity.duration - Double(h)) * 60)
                    StatColumn(label: "Time", value: "\(h)h \(m)m")
                } else {
                    StatColumn(label: "Time", value: "-")
                }

                if let section = activity.section, let classRating = section.classRating {
                    StatColumn(label: "Class", value: formatClassRating(classRating))
                } else {
                    StatColumn(label: "Class", value: "-")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            // Photo carousel (if not hidden)
            if !activity.hidePhotos, !photos.isEmpty {
                if photos.count == 1 {
                    Image(uiImage: photos[0])
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                } else {
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
                    }
                }
            }

            // Action bar
            HStack {
                Spacer()
                Image(systemName: "hand.thumbsup")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "bubble.right")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
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
