import SwiftUI
import CoreData

struct GearPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        entity: Gear.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Gear.name, ascending: true)],
        predicate: NSPredicate(format: "retired == NO")
    ) private var activeGear: FetchedResults<Gear>
    
    @Binding var selectedGear: Gear?
    let onSelect: (Gear?) -> Void
    
    var body: some View {
        NavigationView {
            List {
                // No Gear option
                Button(action: {
                    selectedGear = nil
                    onSelect(nil)
                    dismiss()
                }) {
                    HStack {
                        Text("No Gear")
                        Spacer()
                        if selectedGear == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Active gear
                Section("My Gear") {
                    ForEach(activeGear, id: \.id) { gear in
                        Button(action: {
                            selectedGear = gear
                            onSelect(gear)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(gear.name ?? "Unnamed Gear")
                                        .foregroundColor(.primary)
                                    
                                    if let craftType = gear.craftType, let lapType = gear.defaultLapType {
                                        Text("\(craftType) - \(lapType)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if let craftType = gear.craftType {
                                        Text(craftType)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedGear?.id == gear.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                if activeGear.isEmpty {
                    VStack(spacing: 12) {
                        Text("No gear yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add gear in Settings to track usage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Select Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
