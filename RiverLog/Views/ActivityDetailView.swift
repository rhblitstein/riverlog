import SwiftUI

struct ActivityDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let activity: RiverActivity
    
    @State private var showingEditActivity = false
    
    var photos: [UIImage] {
        if let photoDataArray = activity.photoData as? [Data] {
            return photoDataArray.compactMap { UIImage(data: $0) }
        }
        return []
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
    
    var formattedDateTime: String {
        guard let launchTime = activity.launchTime else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return dateFormatter.string(from: launchTime)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Photo carousel banner - only if photos exist
                if !photos.isEmpty {
                    TabView {
                        ForEach(photos.indices, id: \.self) { index in
                            Image(uiImage: photos[index])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 400)
                                .clipped()
                        }
                    }
                    .frame(height: 400)
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    // Date/time and section in one line with icon
                    HStack(alignment: .top, spacing: 6) {
                        Text(craftIcon(for: activity.craftType ?? ""))
                            .font(.caption)
                        Text(formattedDateTime + " · " + (activity.sectionName ?? ""))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 16)
                    
                    // Title
                    Text(activity.title ?? "Untitled")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 4)
                    
                    // Description
                    if let description = activity.activityDescription, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 2)
                    }
                    
                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DetailStatCell(label: "Distance", value: String(format: "%.1f mi", activity.mileage))
                        DetailStatCell(label: "Class", value: activity.rapidClassification ?? "-")
                        DetailStatCell(label: "Flow", value: String(format: "%.0f %@", activity.flowValue, activity.flowUnit ?? ""))
                        DetailStatCell(label: "Duration", value: String(format: "%.1f hr", activity.duration))
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditActivity = true
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingEditActivity) {
            EditActivityView(activity: activity)
        }
        .ignoresSafeArea(edges: photos.isEmpty ? [] : .top)
    }
}

struct DetailStatCell: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
