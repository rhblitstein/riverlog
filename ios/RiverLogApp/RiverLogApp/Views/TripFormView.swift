import SwiftUI

struct TripFormView: View {
    @StateObject private var viewModel = TripFormViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var tripToEdit: Trip?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Trip Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("River Name *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Colorado River", text: $viewModel.riverName)
                            .textInputAutocapitalization(.words)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Section Name *")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Shoshone", text: $viewModel.sectionName)
                            .textInputAutocapitalization(.words)
                    }
                    
                    DatePicker("Date", selection: $viewModel.tripDate, displayedComponents: .date)
                }
                
                Section("Run Details") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("e.g., III, IV+", text: $viewModel.difficulty)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Flow")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("650", text: $viewModel.flow)
                                .keyboardType(.numberPad)
                        }
                        
                        Picker("Unit", selection: $viewModel.flowUnit) {
                            Text("CFS").tag("cfs")
                            Text("Feet").tag("feet")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Craft Type")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("kayak, raft, etc.", text: $viewModel.craftType)
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration (minutes)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("120", text: $viewModel.durationMinutes)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mileage")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("3.5", text: $viewModel.mileage)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 100)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Trip" : "Log New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.isEditing ? "Update" : "Save") {
                        Task {
                            let success = await viewModel.saveTrip()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                if let trip = tripToEdit {
                    viewModel.loadTrip(trip)
                }
            }
        }
    }
}
