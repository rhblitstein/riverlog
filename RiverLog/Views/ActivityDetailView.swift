import SwiftUI
import CoreData

struct ActivityDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    let activity: RiverActivity
    
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
    
    var formattedDateTime: String {
        guard let date = activity.date else { return "" }
        let calendar = Calendar.current
        
        var dateString = ""
        if calendar.isDateInToday(date) {
            dateString = "Today"
        } else if calendar.isDateInYesterday(date) {
            dateString = "Yesterday"
        } else {
            dateString = date.formatted(date: .abbreviated, time: .omitted)
        }
        
        // Add time if available
        if let launchTime = activity.launchTime {
            let timeString = launchTime.formatted(date: .omitted, time: .shortened)
            return "\(dateString) at \(timeString)"
        }
        
        return dateString
    }
    
    var photos: [UIImage] {
        if let photoDataArray = activity.photoData as? [Data] {
            return photoDataArray.compactMap { UIImage(data: $0) }
        }
        return []
    }
    
    var visibilityIcon: String {
        switch activity.visibility {
        case "Public":
            return "globe"
        case "Friends":
            return "person.2"
        default: // "Private"
            return "lock"
        }
    }
    
    var visibilityText: String {
        switch activity.visibility {
        case "Public":
            return "Everyone can see this activity"
        case "Friends":
            return "Your friends can see this activity"
        default: // "Private"
            return "Only you can see this activity"
        }
    }
    
    var gearDetails: String {
        if let gear = activity.gear {
            var parts: [String] = []
            
            // Add gear name
            if let name = gear.name, !name.isEmpty {
                parts.append(name)
            }
            
            // Add brand and model
            if let brand = gear.brand, !brand.isEmpty {
                if let model = gear.model, !model.isEmpty {
                    parts.append("\(brand) \(model)")
                } else {
                    parts.append(brand)
                }
            } else if let model = gear.model, !model.isEmpty {
                parts.append(model)
            }
            
            // Add lap type
            if let lapType = activity.lapType {
                if lapType == "Paddle Guide", activity.loadSize > 0 {
                    parts.append("\(activity.loadSize) load")
                } else {
                    parts.append(lapType)
                }
            }
            
            return parts.isEmpty ? "-" : parts.joined(separator: " • ")
        } else if let craftType = activity.craftType {
            // No gear, just show craft type
            return craftType
        }
        return "-"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero photo banner (if exists) - TRUE edge to edge
                if !activity.hidePhotos, !photos.isEmpty {
                    GeometryReader { geo in
                        Image(uiImage: photos[0])
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: 300)
                            .clipped()
                    }
                    .frame(height: 300)
                }
                
                // Content with padding
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        // Date/time and section with craft emoji
                        HStack(alignment: .top, spacing: 4) {
                            Text(craftIcon(for: activity.craftType ?? ""))
                                .font(.system(size: 14))
                            
                            Text("\(activity.section?.riverName ?? "") - \(activity.section?.name ?? "") • \(formattedDateTime)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // Title (no icon)
                        Text(activity.title ?? "Untitled")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Quick Notes (if not hidden and exists)
                        if !activity.hideNotes, let notes = activity.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                        
                        // Trip Report (if exists)
                        if let tripReport = activity.tripReport, !tripReport.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Trip Report")
                                    .font(.headline)
                                Text(tripReport)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                        
                        // Private Notes (always private, only show if exists)
                        if let privateNotes = activity.privateNotes, !privateNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("Private Notes")
                                        .font(.headline)
                                    Image(systemName: "lock.fill")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Text(privateNotes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(12)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    // Stats Grid
                    VStack(spacing: 12) {
                        if let section = activity.section {
                            // Row 1: Class and Distance
                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "drop.fill",
                                    label: "Class",
                                    value: section.classRating != nil ? formatClassRating(section.classRating!) : "-",
                                    color: .blue
                                )
                                
                                StatCard(
                                    icon: "arrow.left.and.right",
                                    label: "Distance",
                                    value: section.mileage > 0 ? String(format: "%.1f mi", section.mileage) : "-",
                                    color: .green
                                )
                            }
                            
                            // Row 2: Flow and Duration
                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "drop.triangle.fill",
                                    label: "Flow",
                                    value: (!activity.hideFlow && activity.flowValue > 0) ? "\(Int(activity.flowValue)) \(activity.flowUnit ?? "CFS")" : "-",
                                    color: .blue
                                )
                                
                                StatCard(
                                    icon: "clock.fill",
                                    label: "Duration",
                                    value: (!activity.hideDuration && activity.duration > 0) ? String(format: "%.1f hrs", activity.duration) : "-",
                                    color: .purple
                                )
                            }
                            
                            // Row 3: Gradient and Trip Type
                            HStack(spacing: 12) {
                                StatCard(
                                    icon: "arrow.down.forward",
                                    label: "Gradient",
                                    value: section.gradient > 0 ? "\(Int(section.gradient)) fpm" : "-",
                                    color: .orange
                                )
                                
                                StatCard(
                                    icon: (activity.tripType == "Commercial") ? "briefcase.fill" : "person.fill",
                                    label: "Trip Type",
                                    value: activity.tripType ?? "-",
                                    color: (activity.tripType == "Commercial") ? .indigo : .teal,
                                    smallerText: true
                                )
                            }
                        }
                        
                        // Row 4: Gear - Full width with brand/model/lap details
                        if let gear = activity.gear {
                            let craftType = gear.craftType ?? activity.craftType ?? "Raft"
                            StatCardWithEmoji(
                                emoji: craftIcon(for: craftType),
                                label: "Gear",
                                value: gearDetails,
                                color: .cyan,
                                smallerText: true
                            )
                        } else if let craftType = activity.craftType {
                            StatCardWithEmoji(
                                emoji: craftIcon(for: craftType),
                                label: "Craft",
                                value: craftType,
                                color: .cyan,
                                smallerText: true
                            )
                        } else {
                            StatCardWithEmoji(
                                emoji: "🌊",
                                label: "Craft",
                                value: "-",
                                color: .cyan,
                                smallerText: true
                            )
                        }
                    }

                    // GPS Route Map (if activity has GPS data)
                    if activity.hasGPSData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Route")
                                .font(.headline)

                            RouteMapView(activity: activity)

                            // GPS Stats
                            if activity.totalDistance > 0 || activity.elevationGain > 0 {
                                HStack(spacing: 16) {
                                    if activity.totalDistance > 0 {
                                        HStack(spacing: 6) {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.green)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("GPS Distance")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(String(format: "%.2f mi", activity.totalDistance / 1609.34))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }

                                    if activity.elevationGain > 0 {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.up.right")
                                                .foregroundColor(.orange)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Elev. Gain")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(String(format: "%.0f ft", activity.elevationGain * 3.281))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }

                                    if activity.elevationLoss > 0 {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.down.right")
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Elev. Loss")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Text(String(format: "%.0f ft", activity.elevationLoss * 3.281))
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Visibility fine print at bottom
                    HStack(spacing: 4) {
                        Image(systemName: visibilityIcon)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(visibilityText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Additional Photos (if more than 1)
                    if !activity.hidePhotos, photos.count > 1 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("More Photos")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(photos.dropFirst().enumerated()), id: \.offset) { index, photo in
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical)
            }
        }
        .ignoresSafeArea(edges: photos.isEmpty ? [] : .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditActivityView(activity: activity)
        }
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteActivity()
            }
        } message: {
            Text("Are you sure you want to delete this activity? This cannot be undone.")
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
    
    private func deleteActivity() {
        let firestoreId = activity.firestoreId  // Save before deleting
        
        viewContext.delete(activity)
        
        do {
            try viewContext.save()
            
            // Delete from Firestore
            if let firestoreId = firestoreId, !firestoreId.isEmpty {
                Task {
                    let firestoreService = FirestoreService()
                    try? await firestoreService.deleteActivityFromFirestore(firestoreId: firestoreId)
                }
            }
            
            dismiss()
        } catch {
            print("Error deleting activity: \(error)")
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var smallerText: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(smallerText ? .subheadline : .headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCardWithEmoji: View {
    let emoji: String
    let label: String
    let value: String
    let color: Color
    var smallerText: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(emoji)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(smallerText ? .subheadline : .headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
