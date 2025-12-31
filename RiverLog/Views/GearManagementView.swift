import SwiftUI
import CoreData

struct GearManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: Gear.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Gear.retired, ascending: true),
            NSSortDescriptor(keyPath: \Gear.name, ascending: true)
        ]
    ) private var allGear: FetchedResults<Gear>
    
    @State private var showingAddGear = false
    
    var activeGear: [Gear] {
        allGear.filter { !$0.retired }
    }
    
    var retiredGear: [Gear] {
        allGear.filter { $0.retired }
    }
    
    var body: some View {
        NavigationView {
            List {
                if !activeGear.isEmpty {
                    Section("Active Gear") {
                        ForEach(activeGear, id: \.id) { gear in
                            NavigationLink(destination: GearDetailView(gear: gear)) {
                                GearRowView(gear: gear)
                            }
                        }
                    }
                }
                
                if !retiredGear.isEmpty {
                    Section("Retired Gear") {
                        ForEach(retiredGear, id: \.id) { gear in
                            NavigationLink(destination: GearDetailView(gear: gear)) {
                                GearRowView(gear: gear)
                            }
                        }
                    }
                }
                
                if activeGear.isEmpty && retiredGear.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.wave")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No gear yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add your boats to track usage and stats")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("My Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddGear = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGear) {
                AddGearView()
            }
        }
    }
}

struct GearRowView: View {
    let gear: Gear
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(gear.name ?? "Unnamed Gear")
                .font(.headline)
            
            HStack(spacing: 8) {
                if let craftType = gear.craftType {
                    Text(craftType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let brand = gear.brand, !brand.isEmpty {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let model = gear.model, !model.isEmpty {
                    Text(model)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if gear.length > 0 {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", gear.length))'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if gear.retired {
                Text("Retired")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
