import SwiftUI
import CoreData

struct GearDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var gear: Gear
    
    @State private var showingEditSheet = false
    @State private var showingRetireAlert = false
    
    // Fetch activities that used this gear
    @FetchRequest private var activities: FetchedResults<RiverActivity>
    
    init(gear: Gear) {
        self.gear = gear
        
        // Fetch activities using this gear
        _activities = FetchRequest<RiverActivity>(
            entity: RiverActivity.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \RiverActivity.date, ascending: false)],
            predicate: NSPredicate(format: "gear == %@", gear)
        )
    }
    
    var totalMiles: Double {
        activities.reduce(0) { sum, activity in
            sum + (activity.section?.mileage ?? 0)
        }
    }
    
    var totalTrips: Int {
        activities.count
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(gear.name ?? "Unnamed Gear")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        if let craftType = gear.craftType {
                            Label(craftType, systemImage: "figure.wave")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let brand = gear.brand, !brand.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(brand)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let model = gear.model, !model.isEmpty {
                            Text(model)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if gear.length > 0 {
                        Text("\(String(format: "%.1f", gear.length)) feet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if gear.retired {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .foregroundColor(.orange)
                            Text("Retired")
                                .foregroundColor(.orange)
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                
                // Stats
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "number",
                            label: "Total Trips",
                            value: "\(totalTrips)",
                            color: .blue
                        )
                        
                        StatCard(
                            icon: "arrow.left.and.right",
                            label: "Total Miles",
                            value: String(format: "%.1f mi", totalMiles),
                            color: .green
                        )
                    }
                }
                .padding(.horizontal)
                
                // Recent Activities
                if !activities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activities")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(activities.prefix(5), id: \.id) { activity in
                            NavigationLink(destination: ActivityDetailView(activity: activity)) {
                                ActivityCardView(activity: activity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditSheet = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: { showingRetireAlert = true }) {
                        Label(gear.retired ? "Unretire" : "Retire", systemImage: "pause.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditGearView(gear: gear)
        }
        .alert(gear.retired ? "Unretire Gear?" : "Retire Gear?", isPresented: $showingRetireAlert) {
            Button("Cancel", role: .cancel) { }
            Button(gear.retired ? "Unretire" : "Retire") {
                toggleRetired()
            }
        } message: {
            Text(gear.retired ? "This gear will be moved back to your active gear." : "This gear will be moved to retired, but you can unretire it anytime.")
        }
    }
    
    private func toggleRetired() {
        gear.retired.toggle()
        
        do {
            try viewContext.save()
        } catch {
            print("Error retiring gear: \(error)")
        }
    }
}
