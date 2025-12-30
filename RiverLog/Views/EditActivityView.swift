import SwiftUI

struct EditActivityView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: EditActivityViewModel
    @State private var showingSectionPicker = false
    
    init(activity: RiverActivity) {
        _viewModel = StateObject(wrappedValue: EditActivityViewModel(activity: activity))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Activity Info") {
                    TextField("Title", text: $viewModel.title)
                    TextField("Description (optional)", text: $viewModel.activityDescription)
                }
                
                Section("River Section") {
                    if let section = viewModel.selectedSection {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Selected Section")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Change") {
                                    showingSectionPicker = true
                                }
                                .font(.subheadline)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.riverName ?? "")
                                    .font(.headline)
                                Text(section.name ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    Label("Class \(section.classRating ?? "")", systemImage: "drop.fill")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    if section.mileage > 0 {
                                        Label("\(String(format: "%.1f", section.mileage)) mi", systemImage: "arrow.left.and.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if section.gradient > 0 {
                                        Label("\(Int(section.gradient)) fpm", systemImage: "arrow.down.forward")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        Picker("Craft Type", selection: $viewModel.craftType) {
                            ForEach(viewModel.craftTypes, id: \.self) { type in
                                Text(type)
                            }
                        }
                    } else {
                        Button(action: { showingSectionPicker = true }) {
                            HStack {
                                Label("Select River Section", systemImage: "map")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Trip Details") {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    DatePicker("Launch Time", selection: $viewModel.launchTime, displayedComponents: .hourAndMinute)
                    HStack {
                        Text("Duration (hours)")
                        TextField("0", value: $viewModel.duration, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Flow") {
                    HStack {
                        Text("Flow")
                        TextField("0", value: $viewModel.flowValue, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("", selection: $viewModel.flowUnit) {
                            ForEach(viewModel.flowUnits, id: \.self) { unit in
                                Text(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }
                
                Section("Photos") {
                    PhotoPicker(selectedPhotos: $viewModel.selectedPhotos)
                }
            }
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save(context: viewContext, section: viewModel.selectedSection)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid || viewModel.selectedSection == nil)
                }
            }
            .sheet(isPresented: $showingSectionPicker) {
                RiverSectionPicker(selectedSection: $viewModel.selectedSection)
            }
        }
    }
}
