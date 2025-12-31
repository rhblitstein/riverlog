import SwiftUI
import CoreData

struct AddGearView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var craftType: CraftType = .raft
    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var length: String = ""
    @State private var defaultLapType: LapType? = nil
    @State private var defaultLoadSize: Int = 0
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var availableLapTypes: [LapType] {
        craftType.availableLapTypes
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Gear Info") {
                    TextField("Name (e.g., Work Sotar)", text: $name)
                    
                    Picker("Craft Type", selection: $craftType) {
                        ForEach(CraftType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section("Details (Optional)") {
                    TextField("Brand (e.g., Hyside)", text: $brand)
                    TextField("Model (e.g., Mini-Max)", text: $model)
                    TextField("Length (feet)", text: $length)
                        .keyboardType(.decimalPad)
                }
                
                Section("Defaults") {
                    if !availableLapTypes.isEmpty {
                        Picker("Default Lap Type", selection: $defaultLapType) {
                            Text("None").tag(nil as LapType?)
                            ForEach(availableLapTypes, id: \.self) { type in
                                Text(type.displayName).tag(type as LapType?)
                            }
                        }
                    }
                    
                    if defaultLapType == .paddleGuide {
                        HStack {
                            Text("Default Load Size")
                            TextField("0", value: $defaultLoadSize, format: .number)
                                .keyboardType(.numberPad)
                        }
                    }
                }
            }
            .navigationTitle("Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGear()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func saveGear() {
        let gear = Gear(context: viewContext)
        gear.id = UUID()
        gear.name = name
        gear.craftType = craftType.rawValue
        gear.brand = brand.isEmpty ? nil : brand
        gear.model = model.isEmpty ? nil : model
        gear.length = Double(length) ?? 0
        gear.defaultLapType = defaultLapType?.rawValue
        gear.defaultLoadSize = Int16(defaultLoadSize)
        gear.retired = false
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving gear: \(error)")
        }
    }
}
