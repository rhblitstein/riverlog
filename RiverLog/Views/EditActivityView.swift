import SwiftUI

struct EditActivityView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: EditActivityViewModel
    @State private var showingDeleteConfirmation = false
    
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
                
                Section("River Details") {
                    TextField("Section Name", text: $viewModel.sectionName)
                    Picker("Craft Type", selection: $viewModel.craftType) {
                        ForEach(viewModel.craftTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    Picker("Class", selection: $viewModel.rapidClassification) {
                        ForEach(viewModel.classifications, id: \.self) { classification in
                            Text(classification)
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
                    HStack {
                        Text("Mileage")
                        TextField("0", value: $viewModel.mileage, format: .number)
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
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Activity")
                            Spacer()
                        }
                    }
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
                        viewModel.save(context: viewContext)
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("Delete Activity?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    viewModel.delete(context: viewContext)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}
